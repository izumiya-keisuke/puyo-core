#########
puyo-core
#########

:code:`puyo-core` is a `Puyo Puyo <https://puyo.sega.jp/>`_ library written in `Nim <https://nim-lang.org>`_.

************
Installation
************

::

    nimble install https://github.com/izumiya-keisuke/puyo-core

*****
Usage
*****

With :code:`import puyo_core`, you can use all features provided by this module.
For details, please refer to the `documentation <https://izumiya-keisuke.github.io/puyo-core>`_.

*******
License
*******

Apache-2.0 or MPL-2.0

See `NOTICE <NOTICE>`_ for details.

**************
For Developers
**************

Test
====

::

    nim c -r tests/makeTest.nim
    nimble test

When compiling :code:`tests/makeTest.nim`, you can specify the instruction set used in testing by giving options:
:code:`-d:bmi2=<num>` or/and :code:`-d:avx2=<num>`.

=============  ==============
:code:`<num>`  Description
=============  ==============
0              Not Use
1              Use
2              Both [default]
=============  ==============

Also, for performance comparison, it is possible to specify whether or not the test conducted for alternative
implementations by giving options: :code:`-d:<opt>`.

==============  ============================================================
:code:`<opt>`   Description
==============  ============================================================
altSingleColor  [Bitboard] (Keep binary fields corresponding to each color.)
==============  ============================================================