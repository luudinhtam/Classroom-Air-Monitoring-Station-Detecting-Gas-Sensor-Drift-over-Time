INSERT INTO Air_Station (
    code,
    name,
    location,
    co_warning_threshold,
    co2_warning_threshold,
    max_baseline_drift,
    device_key,
    note,
    is_active,
    created_at
)
VALUES
(
    N'hcm-binhthanh',
    N'Binh Thanh',
    N'123 Xo Viet Nghe Tinh, phuong Binh Thanh, TPHCM',
    0.00, 0.00, 0.00,
    N'123456',
    N'test',
    1,
    '2026-10-06T22:32:17'
),
(
    N'FPTUH',
    N'FPT University HCM',
    N'Khu Cong Nghe Cao, phuong Tang Nhon Phu, TPHCM',
    0.00, 0.00, 0.00,
    N'123456',
    N'test2',
    1,
    '2026-10-06T22:32:30'
),
(
    N'hn-01',
    N'Ha Noi 1',
    N'Ha Noi',
    0.00, 0.00, 0.00,
    N'123456',
    N'test3',
    0,
    '2026-10-06T22:32:49'
),
(
    N'bt-01',
    N'Ben Tre 1',
    N'Ben Tre',
    0.00, 0.00, 0.00,
    N'123456',
    N'test4',
    0,
    '2026-10-06T22:33:14'
),
(
    N'kh-01',
    N'Khanh Hoa 1',
    N'Khanh Hoa',
    0.00, 0.00, 0.00,
    N'123456',
    N'test5',
    1,
    '2026-10-06T22:33:28'
);


INSERT INTO Air_Calibration (
    code,
    name,
    note,
    is_active
)
VALUES (
    N'test',
    N'test for fun',
    N'just for testing',
    1
);


INSERT INTO Air_EmptyWindow (
    code,
    name,
    is_active,
    start_time,
    end_time,
    station_id,
    note,
    created_at
)
VALUES (
    N'test',
    N'test',
    1,
    '2026-10-09T09:00:00',
    '2026-10-09T10:00:00',
    1,
    N'test',
    '2026-10-10T09:25:18'
);