import requests

base_url = "https://sertifikasibag.com/inventory_kapal/api"
auth = ("admin", "admin123")  # Silakan ganti jika admin/admin123 salah
vessel_id = 31

print(f"1. Mengambil komponen untuk Vessel ID: {vessel_id}...")
try:
    url_comp = f"{base_url}/components.php?vessel_id={vessel_id}"
    res_comp = requests.get(url_comp, auth=auth, timeout=10)
    print("Status Code (Components):", res_comp.status_code)
    
    if res_comp.status_code == 200:
        data = res_comp.json().get('data', {})
        mains = data.get('main_components', [])
        if not mains:
            print("ERROR: Tidak ada main_components untuk Vessel ID ini.")
            main_component_id = 1  # Fallback
        else:
            main_component_id = mains[0]['id']
            print(f"Ditemukan Main Component ID: {main_component_id} ({mains[0]['component_name']})")
    else:
        print("Gagal mengambil komponen:", res_comp.text)
        main_component_id = 1
except Exception as e:
    print("Error mengambil komponen:", e)
    main_component_id = 1

print("\n2. Mengirim POST request submit_adjustment...")
url_submit = f"{base_url}/submit_adjustment.php"
payload = {
    "vessel_id": vessel_id,
    "is_existing": 0,  # Kirim sebagai barang baru biar gampang
    "part_name": "Obeng Ketok Test Script",
    "part_number": "OK-999",
    "satuan": "PCS",
    "main_component_id": main_component_id,
    "qty_change": 10.0,
    "harga_satuan": 75000,
    "keterangan": "Test submit barang baru dari script Python",
}

try:
    response = requests.post(url_submit, json=payload, auth=auth, timeout=10)
    print("Status Code:", response.status_code)
    print("Response Body:", response.text)
except Exception as e:
    print("Error submit:", e)
