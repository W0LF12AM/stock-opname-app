<?php
$hash = 'cb467aef520a48d3f4fba1a3da688a7aeed64ae110669cf5fb2a66d0cea87e8b';
$list = ['admin', 'admin123', 'password', '123456', 'stock opname', 'stockopname', 'stock_opname', 'logistik', 'logistik123', 'crew', 'crew123', 'viewer', 'viewer123'];
foreach($list as $p) {
    if (hash('sha256', $p) == $hash) {
        echo "FOUND: $p\n";
    }
}
