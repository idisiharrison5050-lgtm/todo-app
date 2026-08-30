<?php

use Illuminate\Support\Facades\Artisan;

Artisan::command('about-todos', function () {
    $this->comment('Todo App is running on Laravel.');
});
