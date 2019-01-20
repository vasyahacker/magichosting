<?php
//  header("Content-type: application/json; charset=utf-8");

  function response($result, $mess) {
    echo '<span class="'.$result.'">'.$mess.'</span>';
    //echo json_encode([ 'result' => $result, 'mes' => $mess  ], JSON_PRETTY_PRINT);
  }

  if($_POST){

    if(!isset($_POST['sub_dom_name']) || !isset($_POST['file_path'])
       || !file_exists($_POST['file_path'])
       || !preg_match('/^[a-zA-Z0-9\-]{1,62}$/', $_POST['sub_dom_name'])) {

      if(file_exists($_POST['file_path'])) unlink($_POST['file_path']);

      response('error', 'Error!');
      exit();
    }

    $domain = $_POST['sub_dom_name'].'.'.$_SERVER['SERVER_NAME'];
    $sdm_path = "/var/www/$domain/www";
    $site_archive = $_POST['file_path'];

    if(file_exists($sdm_path)) {
      unlink($site_archive);
      response('error', 'Site '.$domain.' already exist!');
      exit();
    }
    if(!mkdir($sdm_path, 0755, true)) {
      unlink($site_archive);
      response('error', 'Create dir error!');
      exit();
    }

    $zip = new ZipArchive;
    $res = $zip->open($site_archive);
    if ($res === TRUE) {
      $zip->extractTo($sdm_path);
      $zip->close();
      response('success', 'Your site address: <a href="http://'.$domain.'">'.$domain.'</a>');
    } else {
      unlink($site_archive);
      response('error', "Couldn't open athive!");
      exit();
    }
    unlink($site_archive);
  }