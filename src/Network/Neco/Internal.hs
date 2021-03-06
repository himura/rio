module Network.Neco.Internal where

import Control.Monad
import Data.Functor.Identity
import Data.Profunctor.Unsafe
import Network.Neco.Types

makeFilter ::
       (reqIn -> reqOut)
    -> (resOut -> resIn)
    -> Filter m reqIn reqOut resOut resIn
makeFilter = dimap
{-# INLINE makeFilter #-}

makeFilterM ::
       Monad m
    => (reqIn -> m reqOut)
    -> (resOut -> m resIn)
    -> Filter m reqIn reqOut resOut resIn
makeFilterM requestFilter responseFilter (Service service) =
    Service $ \req respond -> requestFilter req >>= flip service (responseFilter >=> respond)
{-# INLINE makeFilterM #-}

makeRequestFilter :: (reqIn -> reqOut) -> Filter m reqIn reqOut res res
makeRequestFilter = lmap
{-# INLINE makeRequestFilter #-}

makeRequestFilterM ::
       Monad m => (reqIn -> m reqOut) -> Filter m reqIn reqOut res res
makeRequestFilterM f (Service service) = Service $ \req respond -> f req >>= flip service respond
{-# INLINE makeRequestFilterM #-}

makeResponseFilter :: (resOut -> resIn) -> Filter r req req resOut resIn
makeResponseFilter = rmap
{-# INLINE makeResponseFilter #-}

makeResponseFilterM ::
       Monad m => (resOut -> m resIn) -> Filter m req req resOut resIn
makeResponseFilterM f (Service service) = Service $ \req respond -> service req $ f >=> respond
{-# INLINE makeResponseFilterM #-}

unwrap :: Filter Identity a i i b -> a -> b
unwrap filt a = runIdentity $ runService (filt (Service (flip id))) a return
{-# INLINE unwrap #-}

unwrapRequestFilter :: Filter Identity reqIn reqOut reqOut reqOut -> reqIn -> reqOut
unwrapRequestFilter = unwrap
{-# INLINE unwrapRequestFilter #-}

unwrapResponseFilter :: Filter Identity resOut resOut resOut resIn -> resOut -> resIn
unwrapResponseFilter = unwrap
{-# INLINE unwrapResponseFilter #-}

fmapRequestFilter :: Functor f => Filter Identity reqIn reqOut reqOut reqOut -> Filter m (f reqIn) (f reqOut) req req
fmapRequestFilter filt = makeRequestFilter $ fmap (unwrapRequestFilter filt)
{-# INLINE fmapRequestFilter #-}

fmapResponseFilter :: Functor f => Filter Identity resOut resOut resOut resIn -> Filter m req req (f resOut) (f resIn)
fmapResponseFilter filt = makeResponseFilter $ fmap (unwrapResponseFilter filt)
{-# INLINE fmapResponseFilter #-}
