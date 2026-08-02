<?php
require_once __DIR__ . '\lib\bootstrap.php';
require_once __DIR__ . '\lib\auth.php';
auth_logout();
redirect('login.php');
