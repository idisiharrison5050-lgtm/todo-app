<?php

namespace App\Http\Middleware;

use App\Models\SyncOperation;
use Closure;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

class Idempotency
{
    public function handle(Request $request, Closure $next): Response
    {
        $operationId = $request->header('Idempotency-Key');
        if ($operationId === null || $operationId === '') {
            return $next($request);
        }

        if (strlen($operationId) > 100) {
            return response()->json(['message' => 'The Idempotency-Key header is too long.'], 422);
        }

        $user = $request->user();
        $fingerprint = hash('sha256', $request->method().'|'.$request->path().'|'.json_encode($request->all(), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
        $existing = SyncOperation::where('user_id', $user->id)->where('operation_id', $operationId)->first();

        if ($existing) {
            return $this->replayOrReject($existing, $fingerprint);
        }

        try {
            $response = DB::transaction(function () use ($request, $next, $user, $operationId, $fingerprint) {
                $existing = SyncOperation::where('user_id', $user->id)->where('operation_id', $operationId)->lockForUpdate()->first();
                if ($existing) {
                    return $this->replayOrReject($existing, $fingerprint);
                }

                $response = $next($request);
                if ($response->isSuccessful()) {
                    $body = json_decode($response->getContent(), true);
                    if (is_array($body)) {
                        SyncOperation::create([
                            'user_id' => $user->id,
                            'operation_id' => $operationId,
                            'fingerprint' => $fingerprint,
                            'status_code' => $response->getStatusCode(),
                            'response_body' => $body,
                        ]);
                    }
                }
                return $response;
            });

            return $response;
        } catch (QueryException $exception) {
            // A unique-key collision means another concurrent request won the
            // idempotency race. Its transaction has committed the canonical
            // response, so replay that response instead of leaking a 500.
            if (! $this->isOperationUniqueViolation($exception)) {
                throw $exception;
            }

            $existing = SyncOperation::where('user_id', $user->id)->where('operation_id', $operationId)->first();
            if (! $existing) {
                throw $exception;
            }

            return $this->replayOrReject($existing, $fingerprint);
        }
    }

    private function replayOrReject(SyncOperation $operation, string $fingerprint): Response
    {
        if (!hash_equals($operation->fingerprint, $fingerprint)) {
            return response()->json(['message' => 'The Idempotency-Key was already used for a different request.'], 409);
        }

        return response()->json($operation->response_body, $operation->status_code);
    }

    private function isOperationUniqueViolation(QueryException $exception): bool
    {
        $message = strtolower($exception->getMessage());
        return str_contains($message, 'sync_operations') && (
            str_contains($message, 'unique') ||
            str_contains($message, 'duplicate')
        );
    }
}
