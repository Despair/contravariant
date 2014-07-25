{-# LANGUAGE CPP #-}
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE RankNTypes #-}
-----------------------------------------------------------------------------
-- |
-- Copyright   :  (C) 2014 Edward Kmett
-- License     :  BSD-style (see the file LICENSE)
--
-- Maintainer  :  Edward Kmett <ekmett@gmail.com>
-- Stability   :  provisional
-- Portability :  portable
--
-- The Day convolution of two covariant functors is a covariant functor.
--
-- <http://ncatlab.org/nlab/show/Day+convolution>
----------------------------------------------------------------------------

module Data.Functor.Day
  ( Day(..)
  , day
  , dap
  , assoc, disassoc
  , swapped
  , intro1, intro2
  , elim1, elim2
  , trans1, trans2
  ) where

import Control.Applicative
import Data.Functor.Identity
#ifdef __GLASGOW_HASKELL__
import Data.Typeable
#endif

-- | The Day convolution of two covariant functors.
data Day f g a = forall b c. Day (f b) (g c) (b -> c -> a)
#if defined(__GLASGOW_HASKELL__) && __GLASGOW_HASKELL__ >= 707
  deriving Typeable
#endif

-- | Construct the Day convolution
day :: f (a -> b) -> g a -> Day f g b
day fa gb = Day fa gb id

#if defined(__GLASGOW_HASKELL__) && __GLASGOW_HASKELL__ < 707
instance (Typeable1 f, Typeable1 g) => Typeable1 (Day f g) where
    typeOf1 tfga = mkTyConApp dayTyCon [typeOf1 (fa tfga), typeOf1 (ga tfga)]
        where fa :: t f (g :: * -> *) a -> f a
              fa = undefined
              ga :: t (f :: * -> *) g a -> g a
              ga = undefined

dayTyCon :: TyCon
#if MIN_VERSION_base(4,4,0)
dayTyCon = mkTyCon3 "contravariant" "Data.Functor.Day" "Day"
#else
dayTyCon = mkTyCon "Data.Functor.Day.Day"
#endif

#endif

instance Functor (Day f g) where
  fmap f (Day fb gc bca) = Day fb gc $ \b c -> f (bca b c)

-- | Day convolution provides a monoidal product. The associativity
-- of this monoid is witnessed by 'assoc' and 'disassoc'.
--
-- @
-- 'assoc' . 'disassoc' = 'id'
-- 'disassoc' . 'assoc' = 'id'
-- 'fmap' f '.' 'assoc' = 'assoc' '.' 'fmap' f
-- @
assoc :: Day f (Day g h) a -> Day (Day f g) h a
assoc (Day fb (Day gd he dec) bca) = Day (Day fb gd (,)) he $
  \ (b,d) e -> bca b (dec d e)

-- | Day convolution provides a monoidal product. The associativity
-- of this monoid is witnessed by 'assoc' and 'disassoc'.
--
-- @
-- 'assoc' . 'disassoc' = 'id'
-- 'disassoc' . 'assoc' = 'id'
-- 'fmap' f '.' 'disassoc' = 'disassoc' '.' 'fmap' f
-- @
disassoc :: Day (Day f g) h a -> Day f (Day g h) a
disassoc (Day (Day fb gc bce) hd eda) = Day fb (Day gc hd (,)) $ \ b (c,d) ->
  eda (bce b c) d

-- | The monoid for Day convolution /in Haskell/ is symmetric.
--
-- @
-- 'fmap' f '.' 'swapped' = 'swapped' '.' 'fmap' f
-- @
swapped :: Day f g a -> Day g f a
swapped (Day fb gc abc) = Day gc fb (flip abc)

intro1 :: f a -> Day Identity f a
intro1 fa = Day (Identity ()) fa $ \_ a -> a

intro2 :: f a -> Day f Identity a
intro2 fa = Day fa (Identity ()) const

elim1 :: Functor f => Day Identity f a -> f a
elim1 (Day (Identity b) fc bca) = bca b <$> fc

elim2 :: Functor f => Day f Identity a -> f a
elim2 (Day fb (Identity c) bca) = flip bca c <$> fb

-- | Collapse via a monoidal functor.
dap :: Applicative f => Day f f a -> f a
dap (Day fb fc abc) = liftA2 abc fb fc

-- | Apply a natural transformation to the left-hand side of a Day convolution.
--
-- This respects the naturality of the natural transformation you supplied:
--
-- @
-- 'fmap' f '.' 'trans1' fg = 'trans1' fg '.' 'fmap' f
-- @
trans1 :: (forall x. f x -> g x) -> Day f h a -> Day g h a
trans1 fg (Day fb hc bca) = Day (fg fb) hc bca

-- | Apply a natural transformation to the right-hand side of a Day convolution.
--
-- This respects the naturality of the natural transformation you supplied:
--
-- @
-- 'fmap' f '.' 'trans2' fg = 'trans2' fg '.' 'fmap' f
-- @
trans2 :: (forall x. g x -> h x) -> Day f g a -> Day f h a
trans2 gh (Day fb gc bca) = Day fb (gh gc) bca
