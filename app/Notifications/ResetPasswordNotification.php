<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class ResetPasswordNotification extends Notification
{
    use Queueable;

    public function __construct(private readonly string $token)
    {
    }

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $baseUrl = rtrim((string) config('app.url'), '/');
        $url = $baseUrl.'/reset-password?token='.urlencode($this->token).'&email='.urlencode((string) $notifiable->getEmailForPasswordReset());

        return (new MailMessage)
            ->subject('Reset your Todo App password')
            ->line('We received a request to reset your password.')
            ->action('Reset Password', $url)
            ->line('This link will expire and can only be used once.')
            ->line('If you did not request a password reset, you can ignore this email.');
    }
}
