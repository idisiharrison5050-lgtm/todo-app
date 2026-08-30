<?php

namespace App\Services;

use App\Models\Reminder;
use Carbon\CarbonImmutable;
use InvalidArgumentException;

class ReminderSchedule
{
    public function nextOccurrence(Reminder $reminder, ?CarbonImmutable $from = null): ?CarbonImmutable
    {
        $now = $from ?: CarbonImmutable::now($reminder->timezone);
        $starts = CarbonImmutable::parse($reminder->starts_at)->setTimezone($reminder->timezone);

        if (! $reminder->enabled) {
            return null;
        }

        if ($reminder->type === 'once') {
            return $starts->greaterThanOrEqualTo($now) ? $starts : null;
        }

        $hour = $reminder->hour ?? $starts->hour;
        $minute = $reminder->minute ?? $starts->minute;

        if ($reminder->type === 'daily') {
            $candidate = $now->setTime($hour, $minute);
            return $candidate->greaterThan($now) ? $candidate : $candidate->addDay();
        }

        if ($reminder->type === 'weekdays') {
            $days = array_map('intval', $reminder->weekdays ?: []);
            for ($i = 0; $i < 8; $i++) {
                $candidate = $now->addDays($i)->setTime($hour, $minute);
                if (in_array($candidate->dayOfWeekIso, $days, true) && $candidate->greaterThan($now)) {
                    return $candidate;
                }
            }
            return null;
        }

        if ($reminder->type === 'weekly') {
            $target = $starts->dayOfWeekIso;
            for ($i = 0; $i < 8; $i++) {
                $candidate = $now->addDays($i)->setTime($hour, $minute);
                if ($candidate->dayOfWeekIso === $target && $candidate->greaterThan($now)) {
                    return $candidate;
                }
            }
            return null;
        }

        throw new InvalidArgumentException('Unsupported reminder type.');
    }
}
