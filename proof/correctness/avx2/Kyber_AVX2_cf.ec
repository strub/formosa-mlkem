require import AllCore List Int IntDiv StdOrder CoreMap Real Number.
import IntOrder.
from Jasmin require import JModel.
require import Array16 Array32 Array64 Array128 Array168 Array256 Array384 Array768 Array960 Array1152.
require import Jkem.
require import Kyber.

(* TODO: prove equivalence w/ EncDec reification *)

module EncDec_AVX2 = {
   proc decode12(a : W8.t Array384.t) : ipoly = {
       var i,k;
       var r : ipoly;
       r <- witness;
       i <- 0;

       while (i < 2) {
         k <- 0;

         while (k < 64) {
            r.[128*i + 2*k]  <- to_uint a.[192*i + 3*k] + to_uint a.[192*i + 3*k + 1] %% 2^4 * 2^8;
            r.[128*i + 2*k + 1]  <- to_uint a.[192*i + 3*k + 2] * 2^4 + to_uint a.[192*i + 3*k + 1] %/ 2^4;
            k <- k + 1;
         }
         i <- i + 1;
       }

       return r;
   }

  proc decode12_opt(a : W8.t Array384.t) : ipoly = {

    var i;
    var r : ipoly;
    r <- witness;
    i <- 0;
    while (i < 2) {
      r <- fill (fun k => let b1 = to_uint a.[3 * (k %/ 2) + k %% 2] in
                          let b2 = to_uint a.[3 * (k %/ 2) + k %% 2 + 1] in
                          if (k %% 2 = 0) then b1 + b2 %% 2^4 * 2^8
                          else b2 * 2^4 + b1 %/ 2^4)
                (128 * i) 128 r;

      i <- i + 1;
    }
    return r;
  }

  proc decode12_opt_vec(a : W8.t Array1152.t) : ipolyvec = {
    var a1, a2, a3;
    a1 <@ decode12_opt(subarray384 a 0);
    a2 <@ decode12_opt(subarray384 a 1);
    a3 <@ decode12_opt(subarray384 a 2);
    return fromarray256 a1 a2 a3;
  }

  proc decode10_vec(u : W8.t Array960.t) : ipolyvec = {
    var c : ipolyvec;
    var i,j,k,t0,t1,t2,t3,t4;

    c <- witness;
    k <- 0; j <- 0;
    while (k < 3) {
      i <- 0;
      while(i < 64) {
        t0 <- u.[j]; t1 <- u.[j + 1]; t2 <- u.[j + 2]; t3 <- u.[j + 3]; t4 <- u.[j + 4];
        c.[256 * k + 4 * i] <- to_uint t0 + (to_uint t1 %% 2^2) * 2^8;
        c.[256 * k + 4 * i + 1] <-  to_uint t1 %/ 2^2 + (to_uint t2 %% 2^4) * 2^6;
        c.[256 * k + 4 * i + 2] <-  to_uint t2 %/ 2^4 + (to_uint t3 %% 2^6) * 2^4;
        c.[256 * k + 4 * i + 3] <-  to_uint t3 %/ 2^6 + (to_uint t4) * 2^2;
        j <- j + 5;
        i <- i + 1;
      }
      k <- k + 1;
    }

    return c;
  }

  proc decode10_opt_vec(u: W8.t Array960.t) : ipolyvec = {
    var c : ipolyvec;
    var k;

    c <- witness;
    k <- 0;
    while (k < 3) { 
     c <- fill (fun i => let t0 = u.[5 * (i %/ 4)] in
                          let t1 = u.[5 * (i %/ 4) + 1] in
                          let t2 = u.[5 * (i %/ 4) + 2] in
                          let t3 = u.[5 * (i %/ 4) + 3] in
                          let t4 = u.[5 * (i %/ 4) + 4] in
                          if (i %% 4 = 0) then to_uint t0 + (to_uint t1 %% 2^2) * 2^8
                          else if (i %% 4 = 1) then to_uint t1 %/ 2^2 + (to_uint t2 %% 2^4) * 2^6
                          else if (i %% 4 = 2) then to_uint t2 %/ 2^4 + (to_uint t3 %% 2^6) * 2^4
                          else to_uint t3 %/ 2^6 + (to_uint t4) * 2^2) (256*k) 256 c;
      k <- k + 1;
    }

    return c;
  }

   proc decode4(a : W8.t Array128.t) : ipoly = {
       var i, j;
       var r : ipoly;
       r <- witness;
       i <- 0;
       while (i < 16) {
          j <- 0;
          while(j < 8) {
            r.[16*i+2*j+0]  <- to_uint a.[8*i+j] %% 16;
            r.[16*i+2*j+1]  <- to_uint a.[8*i+j] %/ 16;
            j <- j+1;
          }
          i <- i + 1;
       }
       return r;
   }

  proc decode1(a : W8.t Array32.t) : ipoly = {
    var i,j;
    var r : ipoly;
    r <- witness;
    i <- 0;

    while (i < 4) {
      j <- 0;
      while(j < 8){
        r.[64*i+j*8+0] <- b2i a.[8*i+j].[0];
        r.[64*i+j*8+1] <- b2i a.[8*i+j].[1];
        r.[64*i+j*8+2] <- b2i a.[8*i+j].[2];
        r.[64*i+j*8+3] <- b2i a.[8*i+j].[3];
        r.[64*i+j*8+4] <- b2i a.[8*i+j].[4];
        r.[64*i+j*8+5] <- b2i a.[8*i+j].[5];
        r.[64*i+j*8+6] <- b2i a.[8*i+j].[6];
        r.[64*i+j*8+7] <- b2i a.[8*i+j].[7];
        j <- j + 1;
      }
      i<-i+1;
    }

    return r;
  }

  proc decode1_opt(a : W8.t Array32.t) : ipoly = {
    var i,j;
    var r : ipoly;
    r <- witness;
    i <- 0;
    while (i < 4) {
      j <- 0;
      while(j < 4) {
        r <- Array256.fill (fun k => b2i a.[k %/ 8].[k %% 8]) (32*i + j*8) 8 r;
        j <- j + 1;
      }

      j <- 0;
      while(j < 4) {
        r <- Array256.fill (fun k => b2i a.[k %/ 8].[k %% 8]) (128 + 32*i + j*8) 8 r;
        j <- j + 1;
      }
      i<-i+1;
    }

    return r;
  }

  proc encode12(a : ipoly) : W8.t Array384.t = {
     var fi1,fi2,i,k;
     var r : W8.t Array384.t;
     r <- witness;
     i <- 0;
     while (i < 2) {
       k <- 0;

       while(k < 64) {
         fi1 <- a.[128*i + 2*k];
         fi2 <- a.[128*i + 2*k + 1];
         r.[192*i+3*k] <- W8.of_int fi1;
         r.[192*i+3*k+1] <- W8.of_int ((fi2 %% 2^4) * 2^4 + fi1 %/ 2^8);
         r.[192*i+3*k+2] <- W8.of_int (fi2 %/ 2^4);
         k <- k + 1;
       }

       i <- i + 1;
     }
     return r;
  }

  proc encode12_opt(a : ipoly) : W8.t Array384.t = {
    var fi1,fi2: int;
    var i;
    var r : W8.t Array384.t;
     r <- witness;
    i <- 0;
    while (i < 2) {

      r <- fill (fun k => let fi1 = a.[128*i + 2 * (k %% 192 %/ 3)] in
                          let fi2 = a.[128*i + 2 * (k %% 192 %/ 3) + 1] in
                          if (k %% 3 = 0) then W8.of_int fi1
                          else if (k %% 3 = 1) then W8.of_int ((fi2 %% 2^4) * 2^4 + fi1 %/ 2^8)
                          else W8.of_int (fi2 %/ 2^4))
                (192*i) 192 r;

      i <- i + 1;
    }
    return r;
  }

  proc encode12_opt_vec(a : ipolyvec) : W8.t Array1152.t = {
    var a1, a2, a3;
    a1 <@ encode12_opt(subarray256 a 0);
    a2 <@ encode12_opt(subarray256 a 1);
    a3 <@ encode12_opt(subarray256 a 2);
    return fromarray384 a1 a2 a3;
  }

  proc encode10_vec(a: ipolyvec) : W8.t Array960.t = {
    var i,j,k,t0,t1,t2,t3;
    var c : W8.t Array960.t;
    c <- witness;
    i <- 0; j <- 0;

    while (i < 48) {
      k <- 0;
      while (k < 4) {
        t0 <- a.[16*i + 4*k];
        t1 <- a.[16*i + 4*k + 1];
        t2 <- a.[16*i + 4*k + 2];
        t3 <- a.[16*i + 4*k + 3];
        c.[j] <- W8.of_int t0; j <- j + 1;
        c.[j] <-  W8.of_int (t0 %/ 2^8 + t1 * 2^2); j <- j + 1;
        c.[j] <-  W8.of_int (t1 %/ 2^6 + t2 * 2^4); j <- j + 1;
        c.[j] <-  W8.of_int (t2 %/ 2^4 + t3 * 2^6); j <- j + 1;
        c.[j] <-  W8.of_int (t3 %/ 2^2); j <- j + 1;
        k <- k + 1;
      }
      i <- i + 1;
    }

    return c;
  }

  proc encode10_opt_vec(a : ipolyvec) : W8.t Array960.t = {
    var c : W8.t Array960.t;
    var i;

    c <- witness;
    i <- 0;

    while (i < 48) {
      c <- fill (fun k => let t0 = a.[16*i + 4 * (k %% 20 %/ 5)] in
                          let t1 = a.[16*i + 4 * (k %% 20 %/ 5) + 1] in
                          let t2 = a.[16*i + 4 * (k %% 20 %/ 5) + 2] in
                          let t3 = a.[16*i + 4 * (k %% 20 %/ 5) + 3] in
                          let t5 = a.[16*i + 4 * (k %% 20 %/ 5) + 4] in
                          if (k %% 5 = 0) then W8.of_int t0
                          else if (k %% 5 = 1) then W8.of_int (t0 %/ 2^8 + t1 * 2^2)
                          else if (k %% 5 = 2) then W8.of_int (t1 %/ 2^6 + t2 * 2^4)
                          else if (k %% 5 = 3) then W8.of_int (t2 %/ 2^4 + t3 * 2^6)
                          else W8.of_int (t3 %/ 2^2))
                (20*i) 20 c; (* FIXME *)
      i <- i + 1;
    }
    return c;
  }

   proc encode4(p : ipoly) : W8.t Array128.t = {
       var fi,fi1,i,k;
       var r : W8.t Array128.t;

       r <- witness;
       i <- 0;

       while (i < 4) {
         k <- 0;
         while(k < 32) {
          fi <- p.[64*i+2*k];
          fi1 <- p.[64*i+2*k+1];

          r.[32*i+k] <- W8.of_int (fi + fi1 * 2^4);

          k <- k + 1;
         }

         i <- i + 1;
       }

       return r;
   }

  proc encode1(a : ipoly) : W8.t Array32.t = {
    var i,k,r;
    var ra : W8.t Array32.t;
    ra <- witness;
    i <- 0;
    while (i < 8) {
      k <- 0;
      (* TODO: rewrite as fill ?? *)
      while(k < 4) {
          r <- W8.init(fun j => W8.int_bit a.[32*i+8*k+j] 0);
          ra.[4*i+k] <- r;
          k <- k + 1;
      }
      i <- i + 1;
    }
    return ra;      
  }
}.

module Kyber_AVX2_cf = {
  proc __fqmul_x16 (a b: W16.t Array16.t) : W16.t Array16.t = {
    var i;
    var t: W16.t;
    var rd:W16.t Array16.t;
    rd <- witness;
    i <- 0;
    while(i < 16) {
      t <@ M.__fqmul(a.[i], b.[i]);
      rd.[i] <- t;
      i <- i + 1;
    }

    return (rd);
  }

  proc __red_x16 (r: W16.t Array16.t) : W16.t Array16.t = {
    var i;
    var t: W16.t;

    i <- 0;
    while(i < 16) {
      t <@ M.__barrett_reduce(r.[i]);
      r.[i] <- t;
      i <- i + 1;
    }

    return (r);
  }
}.

theory AVX2_cf.

equiv decode1_corr:
  EncDec_AVX2.decode1_opt ~ EncDec.decode1: ={a} ==> ={res}.
proof.
  proc.
  unroll for {1} ^while.
  unroll for {2} ^while.
  do 8!(unroll for {1} ^while).
  auto => /> &2.
  search Array256.fill.
  rewrite tP => k kb.
  case (248 <= k < 256); 1: by
    move => kkb; rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;smt(Array256.set_eqiE Array256.set_neqiE).
  move => ?;case (240 <= k < 248); 1: by
    move => kkb; rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=
                 (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 8!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (232 <= k < 240); 1: by
   move => kkb; do 2!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 16!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (224 <= k < 232); 1: by
   move => kkb; do 3!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 24!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (120 <= k < 128); 1: by
   move => kkb; do 4!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 128!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (112 <= k < 120); 1: by
   move => kkb; do 5!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 136!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (104 <= k < 112); 1: by
   move => kkb; do 6!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 144!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (96 <= k < 104); 1: by 
   move => kkb; do 7!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 152!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (216 <= k < 224); 1: by
   move => kkb; do 8!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 32!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (208 <= k < 216); 1: by
   move => kkb; do 9!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 40!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (200 <= k < 208); 1: by
   move => kkb; do 10!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 48!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (192 <= k < 200); 1: by
   move => kkb; do 11!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 56!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (88 <= k < 96); 1: by
   move => kkb; do 12!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 160!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (80 <= k < 88); 1: by
   move => kkb; do 13!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 168!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (72 <= k < 80); 1: by
   move => kkb; do 14!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 176!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (64 <= k < 72); 1: by
   move => kkb; do 15!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 184!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (184 <= k < 192); 1: by
   move => kkb; do 16!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 64!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (176 <= k < 184); 1: by
   move => kkb; do 17!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 72!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (168 <= k < 176); 1: by
   move => kkb; do 18!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 80!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (160 <= k < 168); 1: by
   move => kkb; do 19!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 88!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).

  move => *;case (56 <= k < 64); 1: by
   move => kkb; do 20!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 192!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (48 <= k < 56); 1: by
   move => kkb; do 21!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 200!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (40 <= k < 48); 1: by
   move => kkb; do 22!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 208!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (32 <= k < 40); 1: by
   move => kkb; do 23!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 216!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (152 <= k < 160); 1: by
   move => kkb; do 24!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 96!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (144 <= k < 152); 1: by
   move => kkb; do 25!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 104!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (136 <= k < 144); 1: by
   move => kkb; do 26!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 112!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (128 <= k < 136); 1: by
   move => kkb; do 27!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 120!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (24 <= k <32); 1: by
   move => kkb; do 28!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 224!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (16 <= k <24); 1: by
   move => kkb; do 29!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 232!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (8 <= k <16); 1: by
   move => kkb; do 30!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 240!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
  move => *;case (0 <= k <8); 1: by
   move => kkb; do 31!(rewrite (Array256.filliE _ _ _ _ _ kb) /= ifF 1:/# /=);
                 rewrite (Array256.filliE _ _ _ _ _ kb) /= kkb /=;
             do 248!(rewrite Array256.set_neqiE 1..2:/# /=);
             smt(Array256.set_eqiE Array256.set_neqiE).
by smt().
qed.

require import EncDecCorrectness.

lemma encode1_corr :
  equiv [
  EncDec_AVX2.encode1 ~ EncDec.encode1: ={arg}  /\ (Array256.all (fun x => 0 <= x < 2) a{1})  ==> ={res}
  ].
proof.
  proc.
  unroll for {1} ^while.
  unroll for {2} ^while.
  do 8!(unroll for {1} ^while).
  do 32!(unroll for {2} ^while).
  auto => /> &2 Hp.

  have H : forall ii j0 j1 j2 j3 j4 j5 j6 j7 k (v : W8.t Array32.t), 0 <= ii < 32 =>
            j0 = 8*ii => j1 = 8*ii+1 => j2 = 8 * ii + 2 => j3 = 8 * ii + 3 => j4 = 8 * ii + 4 => j5 = 8*ii+5 => j6 = 8*ii+6 => j7 = 8*ii+7 => k = 8*ii =>
            v.[ii <- W8.init (fun (j0 : int) => (int_bit a{2}.[k + j0] 0)%W8)] =
            v.[ii <- W8.of_int
     (((((((a{2}.[j0] %% 256 + a{2}.[j1] * 2) %% 256 + a{2}.[j2] * 4) %% 256 + a{2}.[j3] * 8) %% 256 + a{2}.[j4] * 16) %%
        256 + a{2}.[j5] * 32) %%
       256 + a{2}.[j6] * 64) %%
      256 + a{2}.[j7] * 128)]; last first.
  move : (H 0 0 1 2 3 4 5 6 7 0 witness  _ _ _ _ _ _ _ _ _) => //= <-.
  rewrite -(H _ _ _ _ _ _ _ _ _ 248) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 240) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 232) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 224) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 216) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 208) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 200) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 192) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 184) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 176) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 168) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 160) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 152) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 144) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 136) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 128) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 120) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 112) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 104) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 96) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 88) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 80) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 72) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 64) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 56) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 48) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 40) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 32) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 24) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 16) 1..10:/#.
  rewrite -(H _ _ _ _ _ _ _ _ _ 8) 1..10:/#.
  done.

move => ii _ _ _ _ _ _ _ _ _ v ib -> -> -> -> -> -> -> -> ->.
congr.
rewrite /int_bit /=.
rewrite allP in Hp.
rewrite -(W8.to_uintK' (W8.init _)); congr.
rewrite to_uintE /w2bits /=.
do 8!(rewrite mkseqSr_rw //=); rewrite mkseq0 //=.
do 8!(rewrite BitEncoding.BS2Int.bs2int_cons /=); rewrite BitEncoding.BS2Int.bs2int_nil //=.
by smt().
qed.

equiv decode10_vec_corr:
  EncDec_AVX2.decode10_vec ~ EncDec.decode10_vec: ={u} ==> ={res}.
proof.
  proc.
  swap 2 1.
  unroll for {1} ^while.
  do 3!(unroll for {1} ^while).
  unroll for {2} ^while.
  by auto => />.
qed.

equiv eq_decode10_opt_vec:
  EncDec_AVX2.decode10_opt_vec ~ EncDec_AVX2.decode10_vec: ={u} ==> ={res}.
proof.
  proc.
  while (#pre /\ ={k} /\ 0 <= k{1} <= 3 /\ j{2} = 320*k{2} /\
         (forall j, 0 <= j < 256*k{1} => c{1}.[j] = c{2}.[j])).
    unroll for {2} 2.
    wp; skip; auto => />.
    move => &1 &2 [#] k_lb k_ub c_eq k_tub />.
    rewrite (mulzDr 320 _ _) (mulzDr 256 _ _) mulz1 //=.
    split.
      + move : k_lb k_tub => /#.
      + move => j j_lb j_ub.
        rewrite filliE 1:/# //=.
        rewrite j_ub //=.
        case (j < 256 * k{2}) => j_tub.
          + have -> /=: !(256 * k{2} <= j). by rewrite -ltzNge j_tub.
            rewrite c_eq; first by rewrite j_lb j_tub.
            do (rewrite Array768.set_neqiE 1:/#; first by move : j_tub j_lb => /#).
            done.
          + move : j_tub => /lezNgt j_tlb.
            rewrite j_tlb /=.
            have j_iota: j \in iota_ (256*k{2}) 256; first by rewrite mem_iota j_ub j_tlb.
            move : j_iota.
            do (rewrite Array768.get_setE 1:/#).
            smt(@List @Array768 @Int).
  auto => />.
  move => cL cR k k_tlb _ k_lb k_ub.
  have -> /=: k = 3. move : k_tlb k_ub => /#.
  apply Array768.ext_eq.
qed.

equiv decode10_opt_vec_corr:
  EncDec_AVX2.decode10_opt_vec ~ EncDec.decode10_vec: ={u} ==> ={res}.
proof.
  transitivity EncDec_AVX2.decode10_vec (={u} ==> ={res}) (={u} ==> ={res}).
  smt(). trivial.
  apply eq_decode10_opt_vec.
  apply decode10_vec_corr.
qed.

equiv encode10_vec_corr:
  EncDec_AVX2.encode10_vec ~ EncDec.encode10_vec: a{1} = u{2} ==> ={res}.
proof.
  proc.
  swap 2 1.
  unroll for {1} ^while.
  do 48!(unroll for {1} ^while).
  unroll for {2} ^while.
  by auto => />.
qed.

equiv eq_encode10_opt_vec:
  EncDec_AVX2.encode10_opt_vec ~ EncDec_AVX2.encode10_vec: ={a} ==> ={res}.
proof.
  proc.
  while (#pre /\ ={i} /\ 0 <= i{1} <= 48 /\ j{2} = 20*i{2} /\
         (forall k, 0 <= k < 20*i{1} => c{1}.[k] = c{2}.[k])).
    unroll for {2} 2.
    wp; skip; auto => />.
    move => &1 &2 [#] i_lb i_ub c_eq i_tub />.
    rewrite (mulzDr 20 _ _) mulz1 //=.
    split.
      + move : i_lb i_tub => /#.
      + move => k k_lb k_ub.
        rewrite filliE 1:/# //=.
        rewrite k_ub //=.
        case (k < 20 * i{2}) => k_tub.
          + have -> /=: !(20 * i{2} <= k). by rewrite -ltzNge k_tub.
            rewrite c_eq; first by rewrite k_lb k_tub.
            do (rewrite Array960.set_neqiE 1:/#; first by move : k_tub k_lb => /#).
            done.
          + move : k_tub => /lezNgt k_tlb.
            rewrite k_tlb /=.
            have k_iota: k \in iota_ (20*i{2}) 20; first by rewrite mem_iota k_ub k_tlb.
            move : k_iota.
            do (rewrite Array960.get_setE 1:/#).
            smt(@List @Array960 @Int).
  auto => />.
  move => cL cR i i_tlb _ i_lb i_ub.
  have -> /=: i = 48. move : i_tlb i_ub => /#.
  apply Array960.ext_eq.
qed.

equiv encode10_opt_corr:
  EncDec_AVX2.encode10_opt_vec ~ EncDec.encode10_vec: a{1} = u{2} ==> ={res}.
proof.
  transitivity EncDec_AVX2.encode10_vec (={a} ==> ={res}) (a{1} = u{2} ==> ={res}).
  smt(). trivial.
  apply eq_encode10_opt_vec.
  apply encode10_vec_corr.
qed.

equiv encode12_avx2_corr:
  EncDec_AVX2.encode12 ~ EncDec.encode12: ={a} ==> ={res}.
proof.
  proc.
  unroll for {1} ^while.
  splitwhile  {2} 4:  (i < 128).
  wp. 
  while (0<=k{1}<=64 /\ 128<=i{2}<=256 /\ i{2} = 2*k{1} + 128 /\ j{2} = 192 * i{1} + 3 * k{1} /\ i{1} = 1 /\ ={r,a}).
  auto => /> /#. 
  wp; while (0<=k{1}<=64 /\ 0<=i{2}<=128 /\ i{2} = 2*k{1} /\ j{2} = 192 * i{1} + 3 * k{1} /\ i{1} = 0 /\ ={r,a}).
  auto => /> /#. 
  auto => /> /#.
qed.

equiv eq_encode12_opt:
  EncDec_AVX2.encode12_opt ~ EncDec_AVX2.encode12: ={a} ==> ={res}.
proof.
  proc.
  while (#pre /\ i{1} = i{2} /\ 0 <= i{1} <= 2 /\
         (forall k, 0 <= k < 192 * i{1} => r{1}.[k] = r{2}.[k])).
    unroll for {2} 2.
    wp; skip; auto => />.
    move => &1 &2 [#] i_lb i_ub r1_eq_r2 i_tub />.
    split.
      + move : i_lb i_tub => /#.
      + rewrite (mulzDr 192 _ _) mulz1.
        move => k k_lb k_ub.
        rewrite filliE 1:/# //=.
        rewrite k_ub //=.
        case (k < 192 * i{2}) => k_tub.
          + have -> //=: !(192 * i{2} <= k). move : k_tub => /#.
            rewrite r1_eq_r2; first by rewrite k_lb k_tub.
            do (rewrite Array384.set_neqiE 1:/#; first by move : k_tub k_lb => /#).
            done.
          + move : k_tub => -/lezNgt k_tlb.
            rewrite k_tlb //=.
            do (rewrite Array384.get_setE 1:/#).
            have k_iota: k \in iota_ (192 * i{2}) 192; first by rewrite mem_iota k_ub k_tlb.
            move : k_iota.
            case (k %% 3 = 0) => k_m.
              smt(@Array384 @Int @IntDiv @List).
            case (k %% 3 = 1) => k_m_1.
              smt(@Array384 @Int @IntDiv @List).
            have k_m_2: k %% 3 = 2. move : k_m k_m_1 (modz_cmp k 3) => /#.
              smt(@Array384 @Int @IntDiv @List).
  wp; skip; auto => />.
    move => rL iR rR iR_tlb _ iR_lb iR_ub.
    have -> //=: iR = 2. move : iR_tlb iR_ub => /#.
    apply Array384.ext_eq.
qed.

equiv encode12_opt_corr:
  EncDec_AVX2.encode12_opt ~ EncDec.encode12: ={a} ==> ={res}.
proof.
  transitivity EncDec_AVX2.encode12 (={a} ==> ={res}) (={a} ==> ={res}).
  smt(). trivial.
  apply eq_encode12_opt.
  apply encode12_avx2_corr.
qed.

equiv encode12_opt_vec_corr:
  EncDec_AVX2.encode12_opt_vec ~ EncDec.encode12_vec: ={a} ==> ={res}.
proof.
  proc => /=.
  wp; call encode12_opt_corr.
  wp; call encode12_opt_corr.
  wp; call encode12_opt_corr.
  auto => />.
qed.

equiv decode12_avx2_corr:
  EncDec_AVX2.decode12 ~ EncDec.decode12: ={a} ==> ={res}.
proof.
  proc.
  unroll for {1} ^while.
  do 2!(unroll for {1} ^while).
  unroll for {2} ^while.
  by auto => />.
qed.

equiv eq_decode12_opt:
  EncDec_AVX2.decode12_opt ~ EncDec_AVX2.decode12: ={a} ==> ={res}.
proof.
  proc.
  while (#pre /\ i{1} = i{2} /\ 0 <= i{1} <= 2 /\
         (forall k, 0 <= k < 128 * i{1} => r{1}.[k] = r{2}.[k])).
    unroll for {2} 2.
    wp; skip; auto => />.
    move => &1 &2 [#] i_lb i_ub r1_eq_r2 i_tub />.
    split.
      + move : i_lb i_tub => /#.
      + rewrite (mulzDr 128 _ _) mulz1.
        move => k k_lb k_ub.
        rewrite filliE 1:/# //=.
        rewrite k_ub //=.
        case (k < 128 * i{2}) => k_tub.
          + have -> //=: !(128 * i{2} <= k). move : k_tub => /#.
            rewrite r1_eq_r2; first by rewrite k_lb k_tub.
            do (rewrite Array256.set_neqiE 1:/#; first by move : k_tub k_lb => /#).
            done.
          + move : k_tub => -/lezNgt k_tlb.
            rewrite k_tlb //=.
            do (rewrite Array256.get_setE 1:/#).
            have k_iota: k \in iota_ (128 * i{2}) 128; first by rewrite mem_iota k_ub k_tlb.
            move : k_iota.
            case (k %% 2 = 0) => k_m.
              smt(@Array256 @Int @IntDiv @List).
            have k_m_1: k %% 2 = 1. move : k_m (modz_cmp k 2) => /#.
              smt(@Array256 @Int @IntDiv @List).
  wp; skip; auto => />.
    move => rL iR rR iR_tlb _ iR_lb iR_ub.
    have -> //=: iR = 2. move : iR_tlb iR_ub => /#.
    apply Array256.ext_eq.
qed.

equiv decode12_opt_corr:
  EncDec_AVX2.decode12_opt ~ EncDec.decode12: ={a} ==> ={res}.
proof.
  transitivity EncDec_AVX2.decode12 (={a} ==> ={res}) (={a} ==> ={res}).
  smt(). trivial.
  apply eq_decode12_opt.
  apply decode12_avx2_corr.
qed.

equiv decode12_opt_vec_corr:
  EncDec_AVX2.decode12_opt_vec ~ EncDec.decode12_vec: ={a} ==> ={res}.
proof.
  proc => /=.
  wp; call decode12_opt_corr.
  wp; call decode12_opt_corr.
  wp; call decode12_opt_corr.
  auto => />.
qed.

equiv eq_decode4:
  EncDec_AVX2.decode4 ~ EncDec.decode4: ={a} ==> ={res}.
proc.
unroll for {1} ^while.
do  16!(unroll for {1} ^while).
unroll for {2} ^while.
by auto => />.
qed.

equiv eq_encode4:
  EncDec_AVX2.encode4 ~ EncDec.encode4: ={p} ==> ={res}.
proof.
  proc.
  swap {2} 2 1.
  unroll for {1} ^while.
  do  4!(unroll for {1} ^while).
  unroll for {2} ^while.
  by auto => />.
qed.

end AVX2_cf.
