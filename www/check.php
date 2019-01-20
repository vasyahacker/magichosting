<?php
    header("Content-type: application/json; charset=utf-8");

    function response($result, $mess) {
	echo json_encode([ 'result' => $result, 'mes' => $mess  ], JSON_PRETTY_PRINT);
    }

    if(isset($_POST['subdomain'])) {
	$subdomain = $_POST['subdomain'];
	if(!preg_match('/^[a-zA-Z0-9\-]{1,62}$/', $subdomain)) {
	    response('error','Inavalid subdomain name!');
	    exit();
	}
	if(file_exists('/var/www/'.$subdomain.'.'.$_SERVER['SERVER_NAME'])) {
	    response('error','Subdomain '.$subdomain.' already exist!');
	    exit();
	}
	response('success','Subdomain '.$subdomain.' is available!');
    }