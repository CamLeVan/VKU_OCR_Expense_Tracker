import os
from PIL import Image, ImageDraw, ImageFont

os.makedirs('assets/sample_receipts', exist_ok=True)

def create_receipt_1():
    img = Image.new('RGB', (450, 650), color=(250, 248, 245))
    d = ImageDraw.Draw(img)
    
    # Draw simple dashed border & title
    d.rectangle([10, 10, 440, 640], outline=(180, 180, 180), width=2)
    
    # Draw Text
    lines = [
        ("CO.OPMART DA NANG", 22, True),
        ("478 Dien Bien Phu, Thanh Khe", 14, False),
        ("TEL: 0236.3759.999", 14, False),
        ("--------------------------------------------", 14, False),
        ("HOA DON BAN HANG", 18, True),
        ("So HD: 0012948 - Gio: 14:30", 14, False),
        ("--------------------------------------------", 14, False),
        ("1. Banh mi Sandwich         25.000 đ", 15, False),
        ("2. Sua tuoi Vinamilk        125.000 đ", 15, False),
        ("--------------------------------------------", 14, False),
        ("TONG CONG:              150.000 đ", 20, True),
        ("Tien mat:                200.000 đ", 15, False),
        ("Tien thua:                50.000 đ", 15, False),
        ("--------------------------------------------", 14, False),
        ("Ngay: 25/09/2026", 16, True),
        ("Cam on quy khach - Hen gap lai!", 14, False),
    ]
    
    y = 30
    for line, size, is_bold in lines:
        d.text((30, y), line, fill=(20, 20, 20))
        y += 34
        
    img.save('assets/sample_receipts/hoa_don_coopmart.png')

def create_receipt_2():
    img = Image.new('RGB', (450, 600), color=(252, 252, 250))
    d = ImageDraw.Draw(img)
    
    d.rectangle([10, 10, 440, 590], outline=(150, 150, 150), width=2)
    
    lines = [
        ("HIGHLANDS COFFEE", 22, True),
        ("VKU CAMPUS STORE", 14, False),
        ("--------------------------------------------", 14, False),
        ("1x Phin Sua Da (L)           45,000", 15, False),
        ("1x Phin Den Da (M)           35,000", 15, False),
        ("--------------------------------------------", 14, False),
        ("TOTAL:                  80,000 VND", 20, True),
        ("CASH:                  100,000 VND", 15, False),
        ("CHANGE:                 20,000 VND", 15, False),
        ("--------------------------------------------", 14, False),
        ("DATE: 07/10/2026", 16, True),
        ("THANK YOU FOR YOUR VISIT!", 14, False),
    ]
    
    y = 30
    for line, size, is_bold in lines:
        d.text((30, y), line, fill=(20, 20, 20))
        y += 36
        
    img.save('assets/sample_receipts/hoa_don_highlands.png')

create_receipt_1()
create_receipt_2()
print("Sample receipts generated successfully in assets/sample_receipts/")
