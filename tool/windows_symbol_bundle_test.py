import struct
import unittest
import uuid
from windows_symbol_bundle import matched, pe_identity, pdb_identity


def fixtures(age=2):
    guid = uuid.UUID('12345678-1234-5678-90ab-123456789abc')
    image = bytearray(2048)
    image[:2] = b'MZ'
    struct.pack_into('<I',image,60,128)
    image[128:132] = b'PE\0\0'
    struct.pack_into('<H',image,134,1)
    struct.pack_into('<H',image,148,240)
    struct.pack_into('<H',image,152,0x20b)
    struct.pack_into('<II',image,312,0x1000,28)
    struct.pack_into('<IIII',image,400,1024,0x1000,1024,512)
    record = b'RSDS'+guid.bytes_le+struct.pack('<I',2)+b'C:\\private\\flutter_forge.pdb\0'
    struct.pack_into('<I',image,524,2)
    struct.pack_into('<I',image,528,len(record))
    struct.pack_into('<I',image,536,600)
    image[600:600+len(record)] = record
    pdb = bytearray(2048)
    pdb[:32] = b'Microsoft C/C++ MSF 7.00\r\n\x1aDS\0\0\0'
    struct.pack_into('<I',pdb,32,512)
    struct.pack_into('<I',pdb,44,16)
    struct.pack_into('<I',pdb,52,1)
    struct.pack_into('<I',pdb,512,2)
    struct.pack_into('<IIII',pdb,1024,2,0,28,3)
    struct.pack_into('<III',pdb,1536,20000404,0,age)
    pdb[1548:1564] = guid.bytes_le
    return bytes(image),bytes(pdb)


class SymbolsTest(unittest.TestCase):
    def test_matching_pair(self):
        image,pdb=fixtures()
        self.assertEqual(matched(image,pdb)['pdb'],'flutter_forge.pdb')

    def test_mismatch(self):
        image,pdb=fixtures(age=3)
        with self.assertRaisesRegex(ValueError,'mismatch'):
            matched(image,pdb)

    def test_bad_formats(self):
        for parser in (pe_identity,pdb_identity):
            with self.assertRaises(ValueError):
                parser(b'not symbols')


if __name__ == '__main__':
    unittest.main()
