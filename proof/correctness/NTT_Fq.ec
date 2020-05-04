require import AllCore IntDiv Array256 Array128.
require import Fq.

import Fq.
theory NTT_Fq.

import Kyber_.ZModRing.

module NTT = {
 proc ntt(r : zmod Array256.t,  zetas : zmod Array128.t) : zmod Array256.t = {
   var len, start, j, zetasctr;
   var  t, zeta_;

   zetasctr <- 0;
   len <- 128;
   while (2 <= len) {
    start <- 0;
    while(start < 256) {
       zetasctr <- zetasctr + 1;
       zeta_ <- zetas.[zetasctr]; 
       j <- start;
       while (j < start + len) {
         t <- zeta_ * r.[j + len];
         r.[j + len] <- r.[j] + (-t);
         r.[j]       <- r.[j] + t;
         j <- j + 1;
       }
       start <- j + len;
     }
     len <- len %/ 2;
   }     
   return r;
 }

 proc invntt(r : zmod Array256.t, zetas_inv : zmod Array128.t) : zmod Array256.t = {
   var len, start, j, zetasctr;
   var  t, zeta_;

   zetasctr <- 0;
   len <- 2;
   while (len <= 128) {
    start <- 0;
    while(start < 256) {
       zeta_ <- zetas_inv.[zetasctr]; 
       zetasctr <- zetasctr + 1;
       j <- start;
       while (j < start + len) {
        t <- r.[j];
        r.[j]       <- t + r.[j + len];
        r.[j + len] <- t + (-r.[j + len]);
        r.[j + len] <- zeta_ * r.[j + len];
         j <- j + 1;
       }
       start <- j + len;
     }
     len <- len * 2;
   }
   j <- 0;
   while (j < 256) {
     r.[j] <- r.[j] * zetas_inv.[127]; 
     j <- j + 1;
   }    
   return r;
 }
  
 
}.

axiom ntt_spec _r :
   hoare[ NTT.ntt :
     _r = r /\ Kyber_.Poly.zetas = zetas ==>
       res = Kyber_.Poly.ntt _r ].

axiom invntt_spec _r  :
   hoare[ NTT.invntt :
     _r = r /\ Kyber_.Poly.zetas_inv = zetas_inv ==>
       res = Kyber_.Poly.invntt _r ].

end NTT_Fq.
