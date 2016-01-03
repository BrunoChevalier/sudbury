{-|
Module      : Graphics.Sudbury.Object
Description : Wayland object handling
Copyright   : (c) Auke Booij, 2015
License     : MIT
Maintainer  : auke@tulcod.com
Stability   : experimental

This module can generate Haskell types which will represent Wayland objects,
and can marshal/demarshal values into/out of them.
-}
{-# LANGUAGE Trustworthy #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE ScopedTypeVariables #-}
-- Simply importing Language.Haskell.TH is already considered unsafe.
-- The fact that we only generate some data in a pure way does not matter here.
module Graphics.Sudbury.Object where

import Language.Haskell.TH
import Data.Typeable
import Data.Word
import Data.Char
import Data.Singletons

import Graphics.Sudbury.Protocol.Types

generatePlainType :: String -> [String] -> Dec
generatePlainType name constrs =
  DataD [] (mkName $ capitalize name) [] (map (flip NormalC [] . mkName . capitalize) constrs) []

protocolTypeData :: WLProtocol -> (String , [String])
protocolTypeData prot = (protocolName prot , map interfaceName (protocolInterfaces prot))

class ObjectPackClass (a :: k) where
  data ObjectPack a :: *
instance ObjectPackClass a where
  data ObjectPack a = Pack Word32
-- This instance does not print quite the right type information
-- But at least it gets us some output.
-- IOW, find something neater later.
instance Typeable a => Show (ObjectPack a) where
  show (Pack n) = "<" ++ show (typeRep (Proxy :: Proxy a)) ++ "@" ++ show n ++ ">"

-- | Packages some arbitrary wayland protocol interface (e.g. 'wl_callback' or 'xdg_surface'), which can be reified to a Haskell type using the ObjectPack type
--
-- This is like SomeSing except it's even more anonymous: because we do not even know all relevant kinds at compile time
data ObjectType = forall t. ObjectType (Sing t)

capitalize :: String -> String
capitalize []       = []
capitalize (c : cs) = toUpper c : cs
