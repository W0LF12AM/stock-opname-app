import hashlib

target = "946144ef28163abfa674712c5fbc32a67d99b6dfe879d0479fd8efed0ba6be2c"

# Let's generate a list of candidate passwords
candidates = [
    "admin", "admin123", "administrator", "admin1234", "admin12345",
    "password", "123456", "12345678", "stockopname", "stock opname",
    "stock_opname", "logistik", "logistik123", "viewer", "viewer123",
    "crew", "crew123", "kapal", "kapal123", "logistik_kapal", "stockopname123",
    "stock_opname123", "stock opname123", "stockopname_app", "stock_opname_app"
]

found = False
for c in candidates:
    h = hashlib.sha256(c.encode('utf-8')).hexdigest()
    if h == target:
        print(f"FOUND PASSWORD FOR HASH {target}: '{c}'")
        found = True
        break

if not found:
    print("Not found in simple candidate list.")
