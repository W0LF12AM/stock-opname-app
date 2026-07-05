<?php
require_once 'c:/xampp/htdocs/inventory_kapal/koneksi.php';

$vesselId = 21;

// Count inventory items
$q_inv = mysqli_query($conn, "SELECT COUNT(*) as cnt FROM inventory WHERE vessel_id = '$vesselId'");
$inv = mysqli_fetch_assoc($q_inv);
echo "Inventory items count: " . $inv['cnt'] . "\n";

// Count main components
$q_main = mysqli_query($conn, "SELECT COUNT(*) as cnt FROM main_components WHERE vessel_id = '$vesselId'");
$main = mysqli_fetch_assoc($q_main);
echo "Main components count: " . $main['cnt'] . "\n";

// Count sub components
$q_sub = mysqli_query($conn, "SELECT COUNT(*) as cnt FROM sub_components s INNER JOIN main_components m ON s.main_component_id = m.id WHERE m.vessel_id = '$vesselId'");
$sub = mysqli_fetch_assoc($q_sub);
echo "Sub components count: " . $sub['cnt'] . "\n";
