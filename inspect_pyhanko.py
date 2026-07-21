import pyhanko
from pyhanko import stamp
import pyhanko.sign.signers as signers
print('pyhanko', pyhanko.__version__)
print('stamp attrs', [name for name in dir(stamp) if 'sign' in name.lower()])
print('signers attrs', [name for name in dir(signers) if 'sign' in name.lower()])
