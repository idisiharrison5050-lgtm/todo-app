<?php

namespace Tests\Unit;

use App\Models\Reminder;
use App\Services\ReminderSchedule;
use Carbon\CarbonImmutable;
use Tests\TestCase;

class ReminderScheduleTest extends TestCase
{
    public function test_daily_reminder_returns_next_local_occurrence(): void
    {
        $reminder = new Reminder([
            'timezone' => 'Africa/Lagos',
            'type' => 'daily',
            'starts_at' => '2026-08-30 09:00:00+01:00',
            'hour' => 10,
            'minute' => 30,
            'enabled' => true,
        ]);

        $now = CarbonImmutable::parse('2026-08-30 10:00:00', 'Africa/Lagos');
        $next = (new ReminderSchedule())->nextOccurrence($reminder, $now);

        $this->assertSame('2026-08-30 10:30:00', $next->format('Y-m-d H:i:s'));
        $this->assertSame('Africa/Lagos', $next->getTimezone()->getName());
    }

    public function test_weekday_reminder_skips_non_selected_days(): void
    {
        $reminder = new Reminder([
            'timezone' => 'Africa/Lagos',
            'type' => 'weekdays',
            'starts_at' => '2026-08-30 09:00:00+01:00',
            'hour' => 8,
            'minute' => 0,
            'weekdays' => [1, 3, 5],
            'enabled' => true,
        ]);

        $now = CarbonImmutable::parse('2026-08-30 12:00:00', 'Africa/Lagos');
        $next = (new ReminderSchedule())->nextOccurrence($reminder, $now);

        $this->assertSame('2026-08-31 08:00:00', $next->format('Y-m-d H:i:s'));
    }

    public function test_disabled_reminder_has_no_occurrence(): void
    {
        $reminder = new Reminder([
            'timezone' => 'Africa/Lagos',
            'type' => 'daily',
            'starts_at' => '2026-08-30 09:00:00+01:00',
            'hour' => 10,
            'minute' => 0,
            'enabled' => false,
        ]);

        $this->assertNull((new ReminderSchedule())->nextOccurrence($reminder));
    }
}
