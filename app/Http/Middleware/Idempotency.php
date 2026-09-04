<?php

namespace App\Http\Middleware;

use App\Models\SyncOperation;
use Closure;
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
            if (!hash_equals($existing->fingerprint, $fingerprint)) {
                return response()->json(['message' => 'The Idempotency-Key was already used for a different request.'], 409);
            }
            return response()->json($existing->response_body, $existing->status_code);
        }

        $response = DB::transaction(function () use ($request, $next, $user, $operationId, $fingerprint) {
            $existing = SyncOperation::where('user_id', $user->id)->where('operation_id', $operationId)->lockForUpdate()->first();
            if ($existing) {
                if (!hash_equals($existing->fingerprint, $fingerprint)) {
                    return response()->json(['message' => 'The Idempotency-Key was already used for a different request.'], 409);
                }
                return response()->json($existing->response_body, $existing->status_code);
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
    }
}
