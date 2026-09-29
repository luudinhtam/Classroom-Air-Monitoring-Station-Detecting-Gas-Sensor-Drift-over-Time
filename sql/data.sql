INSERT INTO AppRole(role_code, role_name) VALUES
    (N'ADMIN', N'ADMIN'),
    (N'STATION_MANAGER', N'STATION_MANAGER'),
    (N'OPERATOR', N'OPERATOR'),
    (N'REVIEWER', N'REVIEWER'),
    (N'VIEWER', N'VIEWER');
 
-- Every seeded account has the password 123456.
-- The value below is a PBKDF2 hash in the form iterations:salt:hash, produced by
-- PasswordUtil.main. Replace it with your own before the defence.
DECLARE @h NVARCHAR(200) = N'20000:a0dee5aba0d8cc258ed13fa22d6b729e:7cc4e6fd505db9217ae726189980404174314d771379ca4d98798889d015a124';
INSERT INTO AppUser(username, pass_hash, full_name, role_id)
SELECT v.u, @h, v.n, r.role_id
FROM (VALUES
    (N'admin', N'Tai khoan ADMIN', N'ADMIN'),
    (N'station_manager', N'Tai khoan STATION_MANAGER', N'STATION_MANAGER'),
    (N'operator', N'Tai khoan OPERATOR', N'OPERATOR'),
    (N'reviewer', N'Tai khoan REVIEWER', N'REVIEWER'),
    (N'viewer', N'Tai khoan VIEWER', N'VIEWER')
) AS v(u, n, rc)
JOIN AppRole r ON r.role_code = v.rc;