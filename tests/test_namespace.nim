## Copyright 2026 Dean Hall See LICENSE for details
##

import std/hashes
import unittest2

# module under test:
import namespace

test "NS32 and NS64 identifiers SHOULD exist":
  check declared NS32
  check declared NS64

test "NS32 SHOULD produce a hash value from a dottedString":
  check NS32"world.hello.there" is NamespaceHash32
  check NS64"world.hello.there" is Hash

test "An NS32 result and an NS64 SHOULD NOT compile when comparing":
  check not compiles(NS32"one.two.three" == NS64"one.two.three")

test "A NS32-produced hash value SHOULD compare for equality":
  check NS32"world.hello.there" == 3822554152'u32
  check 894362440 == NS32"one.two.three"

test "A NS64-produced hash value SHOULD compare for equality":
  check -8863172951485739992 == NS64"WORLD.Hello.there"

test "A NS32 and NS64 SHOULD be case insensitive":
  check NS32"world.hello.there" == NS32"WORLD.Hello.there"
  check NS64"one.two.three" == NS64"ONE.TWO.THREE"

test "Empty NS32() SHOULD produce a hash using the domain.package.name of the caller":
  check NS32() == NS32("test.package.test_namespace")
  check NS32() != NS32("test.package.namespace")
