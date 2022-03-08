
require import AllCore IntDiv List Ring ZModP StdOrder IntMin Real RealExp.
require import List_extra Ring_extra RealExp_extra IntDiv_extra For BitEncoding_extra Real_extra RealExp_extra.
require import List_hakyber IntDiv_hakyber.
require import Array128 Array256.
require import Montgomery.
require Matrix.

import IntOrder.

abstract theory DFT.
  clone import Ring.IDomain as Domain.

  clone import Bigalg.BigComRing as BigDom with
    type  CR.t     <= t,
      op  CR.zeror <= Domain.zeror,
      op  CR.oner  <= Domain.oner,
      op  CR.(+)   <= Domain.(+),
      op  CR.([-]) <= Domain.([-]),
      op  CR.( * ) <= Domain.( * ),
      op  CR.invr  <= Domain.invr,
    pred  CR.unit  <= Domain.unit
    proof CR.*.

  realize CR.addrA     by exact: Domain.addrA    .
  realize CR.addrC     by exact: Domain.addrC    .
  realize CR.add0r     by exact: Domain.add0r    .
  realize CR.addNr     by exact: Domain.addNr    .
  realize CR.oner_neq0 by exact: Domain.oner_neq0.
  realize CR.mulrA     by exact: Domain.mulrA    .
  realize CR.mulrC     by exact: Domain.mulrC    .
  realize CR.mul1r     by exact: Domain.mul1r    .
  realize CR.mulrDl    by exact: Domain.mulrDl   .
  realize CR.mulVr     by exact: Domain.mulVr    .
  realize CR.unitP     by exact: Domain.unitP    .
  realize CR.unitout   by exact: Domain.unitout  .

  op a : t.
  op n : { int | 0 < n } as gt0_n.

  hint exact : gt0_n.

  clone import Matrix with
    type  ZR.t     <= t,
      op  size     <= n,
      op  ZR.zeror <= Domain.zeror,
      op  ZR.oner  <= Domain.oner,
      op  ZR.(+)   <= Domain.(+),
      op  ZR.([-]) <= Domain.([-]),
      op  ZR.( * ) <= Domain.( * ),
      op  ZR.invr  <= Domain.invr,
    pred  ZR.unit  <= Domain.unit
    proof ZR.*, ge0_size.

  realize ZR.addrA     by exact: Domain.addrA    .
  realize ZR.addrC     by exact: Domain.addrC    .
  realize ZR.add0r     by exact: Domain.add0r    .
  realize ZR.addNr     by exact: Domain.addNr    .
  realize ZR.oner_neq0 by exact: Domain.oner_neq0.
  realize ZR.mulrA     by exact: Domain.mulrA    .
  realize ZR.mulrC     by exact: Domain.mulrC    .
  realize ZR.mul1r     by exact: Domain.mul1r    .
  realize ZR.mulrDl    by exact: Domain.mulrDl   .
  realize ZR.mulVr     by exact: Domain.mulVr    .
  realize ZR.unitP     by exact: Domain.unitP    .
  realize ZR.unitout   by exact: Domain.unitout  .
  realize ZR.mulf_eq0  by exact: Domain.mulf_eq0 .
  realize ge0_size     by apply/ltzW/gt0_n.
      
  (* `a` is a principle `n`-th root of unity *)
  axiom aXn_eq1 : exp a n = oner.

  axiom sum_aXi_eq0 : forall k, 0 < k < n =>
    BAdd.bigi predT (fun i => exp a (i * k)) 0 n = zeror.

  hint exact : aXn_eq1.

  lemma unit_a : unit a.
  proof. by apply/(@unitP _ (exp a (n - 1))); rewrite mulrC -exprS //; [smt(gt0_n)]. qed.

  hint exact : unit_a.

  lemma sum_aXi_dvd_eq0 : forall k, ! (n %| k) =>
    BAdd.bigi predT (fun i => exp a (i * k)) 0 n = zeror.
  proof.
  move=> k h; pose F i := exp a (i * (k %% n)).
  rewrite -(BAdd.eq_big_int _ _ F) => /= [i rg_i|] @/F => {F}.
    rewrite {2}(divz_eq k n) mulrDr exprD //.
    rewrite !(mulzC i) -mulrA mulrCA (@exprM _ n).
    by rewrite aXn_eq1 expr1z mul1r.
  apply: sum_aXi_eq0; rewrite ltz_pmod //=.
  rewrite ltr_neqAle modz_ge0 1:gtr_eqF //=.
  by rewrite eq_sym; apply: contra h => h; apply: dvdzE.
  qed.

  op dft (v : vector) =
    offunv (fun k => BAdd.bigi predT (fun j => v.[j] * exp a (j * k)) 0 n).

  op dftV (v : vector) =
    offunv (fun k => invr (ofint n) *
      BAdd.bigi predT (fun j => v.[j] * exp a (- (j * k))) 0 n).

  lemma dftK : unit (ofint n) => cancel dft dftV.
  proof.
  move=> ut_n v; apply/eq_vectorP=> i rg_i; rewrite offunvE //=.
  apply: (mulrI (ofint n)) => //; rewrite mulrA divrr // mul1r.
  pose F j := BAdd.bigi predT (fun j' => v.[j'] * exp a (j * (j' - i))) 0 n.
  rewrite -(BAdd.eq_big_int _ _ F) => /= [k rg_k @/F|].
    rewrite /dft !offunvE //= BAdd.mulr_suml.
    rewrite &(BAdd.eq_big_int) => /= k' rg_k'.
    by rewrite -mulrA -exprD // (@mulzC k' k) IntID.mulrBr.
  rewrite /F BAdd.exchange_big => {F} /=.
  pose F j' := v.[j'] * BAdd.bigi predT (fun j => exp a (j * (j' - i))) 0 n.
  rewrite -(BAdd.eq_big_int _ _ F) => /= [k rg_k @/F|].
    by rewrite BAdd.mulr_sumr.
  rewrite /F /= (BAdd.bigD1 _ _ i) 1,2:(mem_range, range_uniq) //=.
  rewrite BAdd.sumri_const 1:/# /= expr0 -/(ofint _) (@mulrC v.[i]).
  rewrite BAdd.big_seq_cond BAdd.big1 ?addr0 //= => j.
  case=> [/mem_range rg_j @/predC1 ne_ji] {F}.
  by rewrite sum_aXi_dvd_eq0 ?mulr0 //; apply/negP=> /dvdzP[q] /#.
  qed.

end DFT.

require import Kyber.
import Zq.
import ZqRing.

theory NTTequiv.

  clone import Bigalg.BigComRing as BigFq with
    type  CR.t        <- Fq,
      op  CR.zeror <- Zq.zero,
      op  CR.oner  <- Zq.one,
      op  CR.(+)   <- Zq.(+),
      op  CR.([-]) <- Zq.([-]),
      op  CR.( * ) <- Zq.( * ),
      op  CR.invr  <- Zq.inv,
    pred  CR.unit  <- Zq.unit.

  op zeta1 = ofint 17.
  op zeta127 = ofint 1628.
  op R = ofint 65536.

  lemma ofintSz i : ofint (i + 1) = Zq.one + ofint i.
  proof. by rewrite /ofint mulrSz. qed.

  lemma addr_int m n : 0 <= m => ofint m + ofint n = ofint (m + n).
  proof.
    elim m => /=; first by rewrite ofint0 add0r.
    move => m le0m; rewrite ofintSz -addrA => ->.
    by rewrite -addrAC ofintSz.
  qed.

  lemma addr_intz m n : ofint m + ofint n = ofint (m + n).
  proof.
    case (0 <= m) => [le0m|/ltrNge ltm0]; first by apply addr_int.
    rewrite -(oppzK m) -(oppzK n) -!opprD !(ofintN (-_)%Int) -opprD.
    rewrite addr_int; first by apply/ltzW/oppr_gt0.
    by rewrite -!ofintN !opprD !opprK.
  qed.

  lemma mulr_int m n : 0 <= m => ofint m * ofint n = ofint (m * n).
  proof.
    elim m => /=; first by rewrite ofint0 mul0r.
    move => m le0m; rewrite mulrDl /= -!addr_intz.
    by rewrite mulrDl ofint1 mul1r => ->.
  qed.

  lemma mulr_intz m n : ofint m * ofint n = ofint (m * n).
  proof.
    case (0 <= m) => [le0m|/ltrNge ltm0]; first by apply mulr_int.
    rewrite -(oppzK m) !mulNr !(ofintN (-_)%Int) mulNr.
    rewrite mulr_int; first by apply/ltzW/oppr_gt0.
    by rewrite mulNr.
  qed.

  lemma exp_ofint m n : 0 <= n => exp (ofint m) n = ofint (exp m n).
  proof.
    elim n => /=; first by rewrite !expr0 ofint1.
    move => n le0n; rewrite !exprD_nneg // => ->.
    by rewrite !expr1 mulr_intz.
  qed.

  (*TODO: specify in the clone of FqpRing*)
  lemma eq_ofint_3329_0 : ofint 3329 = Zq.zero.
  proof. admit. qed.

  lemma modz_ofint m d : ofint d = Zq.zero => ofint m = ofint (m %% d).
  proof.
    rewrite {1}(divz_eq m d) -addr_intz -mulr_intz => ->.
    by rewrite mulr0 add0r.
  qed.

  lemma exp_zeta1_127 : R * exp zeta1 127 = zeta127.
  proof.
    rewrite exp_ofint //= expr0 /R /zeta127 mulr_int //=.
    by rewrite (modz_ofint _ _ eq_ofint_3329_0).
  qed.

  lemma exp_zeta1_128 : exp zeta1 128 = -Zq.one.
  proof.
    rewrite exp_ofint //= expr0 /= -ofint1 -ofintN.
    by rewrite (modz_ofint _ _ eq_ofint_3329_0) (modz_ofint (-1) _ eq_ofint_3329_0).
  qed.

  lemma exp_zeta1_256 : exp zeta1 256 = Zq.one.
  proof.
    rewrite exp_ofint //= expr0 /= -ofint1.
    by rewrite (modz_ofint _ _ eq_ofint_3329_0).
  qed.

  lemma dvdz_exp (x : Fq) (m d : int) : d %| m => exp x d = Zq.one => exp x m = Zq.one.
  proof. by move => /dvdzP [q ->>]; rewrite mulrC exprM => ->; rewrite expr1z. qed.

  op zetasctr_ntt5 len start = (start * 2 + 1) * (64 %/ len).

  lemma zetasctr_ntt5_ge0 len start :
    0 <= len =>
    0 <= start =>
    0 <= zetasctr_ntt5 len start.
  proof.
    move => le0len le0start; rewrite /zetasctr_ntt5.
    apply/mulr_ge0; first by apply/addr_ge0 => //; apply mulr_ge0.
    by move: le0len => [lt0len|//=]; apply/divz_ge0.
  qed.

  module NTT5 = {
    proc ntt(r : Fq Array256.t) : Fq Array256.t = {
      var len, start, j, zetasctr;
      var t, zeta_;

      zetasctr <- 0;
      len <- 1;
      while (len <= 64) {
       start <- 0;
       while(start < len) {
          zetasctr <- zetasctr_ntt5 len start;
          zeta_ <- exp zeta1 zetasctr;
          j <- 0;
          while (j < 256) {
            t <- zeta_ * r.[bitrev 8 (j + len + start)];
            r.[bitrev 8 (j + len + start)] <- r.[bitrev 8 (j + start)] + (-t);
            r.[bitrev 8 (j + start)]       <- r.[bitrev 8 (j + start)] + t;
            j <- j + (len * 2);
          }
          start <- start + 1;
        }
        len <- len * 2;
      }     
      return r;
    }

   (*TODO*)
    proc invntt(r : Fq Array256.t, zetas_inv : Fq Array128.t) : Fq Array256.t = {
      var len, start, j, zetasctr;
      var  t, zeta_;

      zetasctr <- 0;
      len <- 128;
      while (2 <= len) {
        start <- 0;
        while (start < 128 %/ len) {
          zetasctr <- bitrev 8 ((256 %/ len) + (start %/ len));
          zeta_ <- exp zeta1 zetasctr;
          j <- 0;
          while (j < 256) {
            t <- r.[bitrev 8 (j + start)];
            r.[bitrev 8 (j + start)]       <- t + r.[bitrev 8 (j + start + len)];
            r.[bitrev 8 (j + start + len)] <- t + (-r.[bitrev 8 (j + start + len)]);
            r.[bitrev 8 (j + start + len)] <- zeta_ * r.[bitrev 8 (j + start + len)];
            j <- j + (128 %/ len);
          }
          start <- start + 1;
        }
        len <- len %/ 2;
      }
      j <- 0;
      while (j < 256) {
        r.[j] <- r.[j] * zetas_inv.[127]; 
        j <- j + 1;
      }    
      return r;
    }
  }.

  module NTT4 = {
    proc ntt(r : Fq Array256.t) : Fq Array256.t = {
      var len, start, j, zetasctr;
      var t, zeta_;

      zetasctr <- 0;
      len <- 128;
      while (2 <= len) {
        start <- 0;
        while(start < 256) {
          zetasctr <- bitrev 8 ((256 %/ len) + (start %/ len));
          zeta_ <- exp zeta1 zetasctr;
          j <- 0;
          while (j < len) {
            t <- zeta_ * r.[j + len + start];
            r.[j + len + start] <- r.[j + start] + (-t);
            r.[j + start]       <- r.[j + start] + t;
            j <- j + 1;
          }
          start <- start + (len * 2);
        }
        len <- len %/ 2;
      }     
      return r;
    }

    proc invntt(r : Fq Array256.t) : Fq Array256.t = {
      var len, start, j, zetasctr;
      var  t, zeta_;

      zetasctr <- 0;
      len <- 2;
      while (len <= 128) {
        start <- 0;
        while(start < 256) {
          zetasctr <- bitrev 8 ((256 %/ len) + (start %/ len));
          zeta_ <- exp zeta1 zetasctr;
          j <- 0;
          while (j < len) {
            t <- r.[j + start];
            r.[j + start]       <- t + r.[j + start + len];
            r.[j + start + len] <- t + (-r.[j + start + len]);
            r.[j + start + len] <- zeta_ * r.[j + start + len];
            j <- j + 1;
          }
          start <- start + (len * 2);
        }
        len <- len * 2;
      }
      j <- 0;
      while (j < 256) {
        r.[j] <- r.[j] * zeta127; 
        j <- j + 1;
      }    
      return r;
    }
  }.

  module NTT3 = {
    proc ntt(r : Fq Array256.t,  zetas : Fq Array128.t) : Fq Array256.t = {
      var len, start, j, zetasctr;
      var t, zeta_;

      zetasctr <- 0;
      len <- 128;
      while (2 <= len) {
        start <- 0;
        while(start < 256) {
          zetasctr <- (128 %/ len) + (start %/ (len * 2));
          zeta_ <- zetas.[zetasctr]; 
          j <- 0;
          while (j < len) {
            t <- zeta_ * r.[j + len + start];
            r.[j + len + start] <- r.[j + start] + (-t);
            r.[j + start]       <- r.[j + start] + t;
            j <- j + 1;
          }
          start <- start + (len * 2);
        }
        len <- len %/ 2;
      }     
      return r;
    }

    proc invntt(r : Fq Array256.t, zetas_inv : Fq Array128.t) : Fq Array256.t = {
      var len, start, j, zetasctr;
      var  t, zeta_;

      zetasctr <- 0;
      len <- 2;
      while (len <= 128) {
        start <- 0;
        while(start < 256) {
          zetasctr <- 128 - (256 %/ len) + (start %/ (len * 2));
          zeta_ <- zetas_inv.[zetasctr];
          j <- 0;
          while (j < len) {
            t <- r.[j + start];
            r.[j + start]       <- t + r.[j + start + len];
            r.[j + start + len] <- t + (-r.[j + start + len]);
            r.[j + start + len] <- zeta_ * r.[j + start + len];
            j <- j + 1;
          }
          start <- start + (len * 2);
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

  module NTT2 = {
    proc ntt(r : Fq Array256.t,  zetas : Fq Array128.t) : Fq Array256.t = {
      var len, start, j, zetasctr;
      var t, zeta_;

      zetasctr <- 0;
      len <- 128;
      while (2 <= len) {
        start <- 0;
        while(start < 256) {
          zetasctr <- (128 %/ len) + (start %/ (len * 2));
          zeta_ <- zetas.[zetasctr];
          j <- start;
          while (j < start + len) {
            t <- zeta_ * r.[j + len];
            r.[j + len] <- r.[j] + (-t);
            r.[j]       <- r.[j] + t;
            j <- j + 1;
          }
          start <- start + (len * 2);
        }
        len <- len %/ 2;
      }     
      return r;
    }

    proc invntt(r : Fq Array256.t, zetas_inv : Fq Array128.t) : Fq Array256.t = {
      var len, start, j, zetasctr;
      var  t, zeta_;

      zetasctr <- 0;
      len <- 2;
      while (len <= 128) {
        start <- 0;
        while(start < 256) {
          zetasctr <- 128 - (256 %/ len) + (start %/ (len * 2));
          zeta_ <- zetas_inv.[zetasctr];
          j <- start;
          while (j < start + len) {
            t <- r.[j];
            r.[j]       <- t + r.[j + len];
            r.[j + len] <- t + (-r.[j + len]);
            r.[j + len] <- zeta_ * r.[j + len];
            j <- j + 1;
          }
          start <- start + (len * 2);
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

  module NTT1 = {
    proc ntt(r : Fq Array256.t,  zetas : Fq Array128.t) : Fq Array256.t = {
      var len, start, j, zetasctr;
      var t, zeta_;

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
          start <- start + (len * 2);
        }
        len <- len %/ 2;
      }     
      return r;
    }

    proc invntt(r : Fq Array256.t, zetas_inv : Fq Array128.t) : Fq Array256.t = {
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
          start <- start + (len * 2);
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

  module NTT = {
    proc ntt(r : Fq Array256.t,  zetas : Fq Array128.t) : Fq Array256.t = {
      var len, start, j, zetasctr;
      var t, zeta_;

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

    proc invntt(r : Fq Array256.t, zetas_inv : Fq Array128.t) : Fq Array256.t = {
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

  (*Proof not done and ugly, two lemmas might be useful:*)
  (*- one that gives a postcondition when the loop being adressed is a for loop*)
  (*- another that does the same for the specific for loops that always write on different parts of the memory that is described in the postcondition (the two innermost loops in our case)*)

  abbrev set2_add_mulr (p : Fq Array256.t, z : Fq, a b : int) =
    (p.[b <- p.[a] + - z * p.[b]].[a <- p.[b <- p.[a] + - z * p.[b]].[a] + z * p.[b]])%CR.

  (*TODO: this lemma's version in Jasmin has a useless hypothesis.*)
  lemma nosmt set_neqiE (t : Fq Array256.t) x y a :
    y <> x => t.[x <- a].[y] = t.[y].
  proof. by rewrite get_set_if => /neqF ->. qed.

  lemma set2_add_mulr_eq1iE (p : Fq Array256.t, z : Fq, a b x : int) :
    a <> b =>
    a \in range 0 256 =>
    x = a =>
    (set2_add_mulr p z a b).[x] = (p.[a] + z * p.[b])%CR.
  proof. by move => ? /mem_range ? ?; rewrite set_eqiE ?set_neqiE. qed.

  lemma set2_add_mulr_eq2iE (p : Fq Array256.t, z : Fq, a b x : int) :
    a <> b =>
    b \in range 0 256 =>
    x = b =>
    (set2_add_mulr p z a b).[x] = (p.[a] + - z * p.[b])%CR.
  proof. by move => ? /mem_range ? eqxb; rewrite set_neqiE ?set_eqiE // eqxb eq_sym. qed.

  lemma set2_add_mulr_neqiE (p : Fq Array256.t, z : Fq, a b x : int) :
    x <> a =>
    x <> b =>
    (set2_add_mulr p z a b).[x] = p.[x].
  proof. by move => ? ?; rewrite !set_neqiE. qed.

  abbrev index (len start bsj : int) = bitrev 8 (bsj * len + start).

  lemma index_range (k start bsj : int) :
    k \in range 0 8 =>
    start \in range 0 (2 ^ k) =>
    bsj \in range 0 (2 ^ (8 - k)) =>
    bsj * (2 ^ k) + start \in range 0 256.
  proof.
    move => /mem_range [? ?] Hstart_range Hbsj_range.
    move: (range_mul_add _ _ _ _ _ Hbsj_range Hstart_range) => /=.
    apply range_incl => //.
    by rewrite -exprD_nneg -?addrA ?subr_ge0 //= ltzW.
  qed.

  lemma index_range_k (k start bsj : int) :
    k \in range 0 7 =>
    start \in range 0 (2 ^ k) =>
    bsj \in range 0 (2 ^ (8 - k)) =>
    bsj * (2 ^ k) + start \in range 0 256.
  proof. by move => Hk_range; apply index_range; move: Hk_range; apply range_incl. qed.

  lemma index_range_incr_k (k start bsj : int) :
    k \in range 0 7 =>
    start \in range 0 (2 ^ (k + 1)) =>
    bsj \in range 0 (2 ^ (7 - k)) =>
    bsj * (2 ^ (k + 1)) + start \in range 0 256.
  proof.
    move => Hk_range Hstart_range Hbsj_range; apply index_range => //.
    + by move: (range_add _ 1 _ _ Hk_range); apply range_incl.
    by rewrite opprD /= addrC.
  qed.

  lemma index_bijective (k start bsj x y : int) :
    k \in range 0 8 =>
    start \in range 0 (2 ^ k) =>
    bsj \in range 0 (2 ^ (8 - k)) =>
    x \in range 0 (2 ^ k) =>
    y \in range 0 (2 ^ (8 - k)) =>
    index (2 ^ k) x y = index (2 ^ k) start bsj <=> (x = start) /\ (y = bsj).
  proof.
    move => Hk_range Hstart_range Hbsj_range Hx_range Hy_range.
    by rewrite bitrev_bijective //; [apply index_range|apply index_range|rewrite range_mul_add_eq].
  qed.

  lemma index_bijective_k (k start bsj x y : int) :
    k \in range 0 7 =>
    start \in range 0 (2 ^ k) =>
    bsj \in range 0 (2 ^ (8 - k)) =>
    x \in range 0 (2 ^ k) =>
    y \in range 0 (2 ^ (8 - k)) =>
    index (2 ^ k) x y = index (2 ^ k) start bsj <=> (x = start) /\ (y = bsj).
  proof. by move => Hk_range; apply index_bijective; move: Hk_range; apply range_incl. qed.

  lemma index_bijective_incr_k (k start bsj x y : int) :
    k \in range 0 7 =>
    start \in range 0 (2 ^ (k + 1)) =>
    bsj \in range 0 (2 ^ (7 - k)) =>
    x \in range 0 (2 ^ (k + 1)) =>
    y \in range 0 (2 ^ (7 - k)) =>
    index (2 ^ (k + 1)) x y = index (2 ^ (k + 1)) start bsj <=> (x = start) /\ (y = bsj).
  proof.
    move => Hk_range Hstart_range Hbsj_range Hx_range Hy_range; apply index_bijective => //.
    + by move: (range_add _ 1 _ _ Hk_range); apply range_incl.
    + by rewrite opprD /= addrC.
    by rewrite opprD /= addrC.
  qed.

  lemma index_bijective_incr_k_start (k start bsj x y : int) :
    k \in range 0 7 =>
    start \in range 0 (2 ^ k) =>
    bsj \in range 0 (2 ^ (7 - k)) =>
    x \in range 0 (2 ^ (k + 1)) =>
    y \in range 0 (2 ^ (7 - k)) =>
    index (2 ^ (k + 1)) x y = index (2 ^ (k + 1)) start bsj <=> (x = start) /\ (y = bsj).
  proof.
    move => Hk_range Hstart_range; apply index_bijective_incr_k => //.
    move: Hstart_range; apply range_incl => //.
    apply ler_weexpn2l => //; split; first by move/mem_range: Hk_range.
    by move => _; apply/ltzW/ltzS.
  qed.

  lemma index_bijective_incr_k_len_start (k start bsj x y : int) :
    k \in range 0 7 =>
    start \in range 0 (2 ^ k) =>
    bsj \in range 0 (2 ^ (7 - k)) =>
    x \in range 0 (2 ^ (k + 1)) =>
    y \in range 0 (2 ^ (7 - k)) =>
    index (2 ^ (k + 1)) x y = index (2 ^ (k + 1)) ((2 ^ k) + start) bsj <=>
    (x = (2 ^ k) + start) /\ (y = bsj).
  proof.
    move => Hk_range Hstart_range Hbsj_range Hx_range Hy_range; apply index_bijective_incr_k => //.
    rewrite (addzC _ start); move: (range_add _ (2 ^ k) _ _ Hstart_range); apply range_incl => //=.
    + by apply expr_ge0.
    by rewrite addr_double -exprSr //; move/mem_range: Hk_range.
  qed.

  (*TODO: must be modified to account for the R * *)
  op exponent (len start x : int) = (2 * start + 1) * (bitrev 8 (2 * (x %% len))).

  lemma exponent_0 : exponent 1 0 0 = 0.
  proof. by rewrite /exponent /= bitrev0. qed.

  lemma exponent_ge0 len start x :
    0 <= start =>
    0 <= exponent len start x.
  proof.
    move => le0start; apply/mulr_ge0; first by apply/addr_ge0 => //; apply/mulr_ge0.
    (*TODO: Pierre-Yves*)
    (*by move/mem_range: (bitrev_range 8 (2 * (x %% len))).*)
    by apply bitrev_ge0.
  qed.

  lemma exponent_spec_00 (k start x : int) :
    k \in range 0 7 =>
    start \in range 0 (2 ^ k) =>
    x \in range 0 (2 ^ k) =>
    exp zeta1 (exponent (2 ^ k) start x) =
    exp zeta1 (exponent (2 ^ (k + 1)) start x).
  proof.
    move => Hk_range Hstart_range Hx_range.
    rewrite /exponent !modz_small // -mem_range normrX_nat //=.
    + by move/mem_range: Hk_range.
    + by apply/addr_ge0 => //; move/mem_range: Hk_range.
    move: Hx_range; apply range_incl => //=.
    apply/ler_weexpn2l => //; split; first by move/mem_range: Hk_range.
    by move => _; apply/ltzW/ltzS.
  qed.

  lemma exponent_spec_01 (k start x : int) :
    k \in range 0 7 =>
    start \in range 0 (2 ^ k) =>
    x \in range 0 (2 ^ k) =>
    exp zeta1 (zetasctr_ntt5 (2 ^ k) start + exponent (2 ^ k) start x) =
    exp zeta1 (exponent (2 ^ (k + 1)) start (2 ^ k + x)).
  proof.
    move => Hk_range Hstart_range Hx_range.
    rewrite /exponent !modz_small // -?mem_range ?normrX_nat //=.
    + by move/mem_range: Hk_range.
    + by apply/addr_ge0 => //; move/mem_range: Hk_range.
    + rewrite (IntID.addrC _ x); move: (range_add _ (2 ^ k) _ _ Hx_range) => /=.
      rewrite addr_double -exprSr; first by move/mem_range: Hk_range.
      by apply range_incl => //=; apply expr_ge0.
    rewrite mulrDr -exprS; first by move/mem_range: Hk_range.
    rewrite /zetasctr_ntt5 (IntID.mulrC _ 2) -mulrDr.
    do 2!congr.
    move: (range_mul _ _ _ 2 _ Hx_range) => //= {Hx_range} Hx_range.
    move: (range_incl _ _ _ 0 (2 ^ (k + 1)) _ _ Hx_range) => // {Hx_range}.
    + by rewrite mulrDl /= ltzW ltzE /= exprSr //; move/mem_range: Hk_range.
    rewrite (IntID.mulrC _ 2) => Hx_range.
    rewrite divz_pow //=; first by rewrite -(ltzS _ 6) /= -mem_range.
    move: (bitrev_add _ 8 _ 1 _ Hx_range) => /=.
    + by split; [apply/addr_ge0 => //|move => _; apply/ltzW/ltr_subr_addr]; move/mem_range: Hk_range => //.
    rewrite (addzC (_ * _)%Int) (addzC (bitrev _ _)%Int) bitrev1 //= => ->.
    rewrite divz_pow //=.
    + by split; [apply/addr_ge0 => //|move => _; apply/ltzE]; move/mem_range: Hk_range => //.
    by rewrite opprD addrA IntID.addrAC.
  qed.

  lemma exponent_spec_10 (k start x : int) :
    k \in range 0 7 =>
    start \in range 0 (2 ^ k) =>
    x \in range 0 (2 ^ k) =>
    exp zeta1 (exponent (2 ^ k) start x) =
    exp zeta1 (exponent (2 ^ (k + 1)) (2 ^ k + start) x).
  proof.
    move => Hk_range Hstart_range Hx_range.
    rewrite /exponent !modz_small // -?mem_range ?normrX_nat //=.
    + by move/mem_range: Hk_range.
    + by apply/addr_ge0 => //; move/mem_range: Hk_range.
    + move: Hx_range; apply range_incl => //=.
      apply/ler_weexpn2l => //; split; first by move/mem_range: Hk_range.
      by move => _; apply/ltzW/ltzS.
    rewrite mulrDr -exprS; first by move/mem_range: Hk_range.
    rewrite -addrA (IntID.mulrDl (2 ^ (k + 1))).
    rewrite exprD_nneg.
    + by apply/mulr_ge0; [apply/expr_ge0|apply/bitrev_ge0].
    + by apply/mulr_ge0; [apply/addr_ge0 => //; apply/mulr_ge0 => //; move/mem_range: Hstart_range|apply/bitrev_ge0].
    rewrite (dvdz_exp _ (_ ^ _ * _)%IntID _ _ exp_zeta1_256) ?mul1r //.
    move: (dvdz_mul (2 ^ (k + 1)) (2 ^ (7 - k)) (2 ^ (k + 1)) (bitrev 8 (2 * x))).
    rewrite -exprD_nneg.
    + by apply/addr_ge0 => //; move/mem_range: Hk_range.
    + by apply/subr_ge0/ltzW; move/mem_range: Hk_range.
    rewrite addrA /= addrAC /= => -> //; first by apply dvdzz.
    rewrite mulrC.
    move: (range_mul _ _ _ 2 _ Hx_range) => //= {Hx_range} Hx_range.
    move: (range_incl _ _ _ 0 (2 ^ (k + 1)) _ _ Hx_range) => // {Hx_range}; last move => Hx_range.
    + by rewrite mulrDl /= ltzW ltzE /= exprSr //; move/mem_range: Hk_range.
    apply bitrev_range_dvdz; last by rewrite opprD addrA /= (addzC 1).
    by split; [apply/subr_ge0/ltzW|move => _; apply/ler_subl_addl/ler_subl_addr/ltzW/ltzE]; move/mem_range: Hk_range.
  qed.

  lemma exponent_spec_11 (k start x : int) :
    k \in range 0 7 =>
    start \in range 0 (2 ^ k) =>
    x \in range 0 (2 ^ k) =>
    exp zeta1 (128 + zetasctr_ntt5 (2 ^ k) start + exponent (2 ^ k) start x) =
    exp zeta1 (exponent (2 ^ (k + 1)) (2 ^ k + start) (2 ^ k + x)).
  proof.
    move => Hk_range Hstart_range Hx_range.
    rewrite /exponent !modz_small // -?mem_range ?normrX_nat //=.
    + by move/mem_range: Hk_range.
    + by apply/addr_ge0 => //; move/mem_range: Hk_range.
    + rewrite (IntID.addrC _ x); move: (range_add _ (2 ^ k) _ _ Hx_range) => /=.
      rewrite addr_double -exprSr; first by move/mem_range: Hk_range.
      by apply range_incl => //=; apply expr_ge0.
    do 2!(rewrite mulrDr -exprS; first by move/mem_range: Hk_range).
    rewrite /zetasctr_ntt5 (IntID.mulrC _ 2) -addrA -mulrDr.
    rewrite -addrA (IntID.mulrDl _ _ (bitrev _ _)).
    rewrite divz_pow //=; first by rewrite -(ltzS _ 6) /= -mem_range.
    rewrite exprD_nneg //.
    + by apply/mulr_ge0; apply addr_ge0 => //; [apply/mulr_ge0 => //; move/mem_range: Hstart_range|apply/expr_ge0|apply/bitrev_ge0].
    rewrite exprD_nneg //.
    + by apply/mulr_ge0; [apply/expr_ge0|apply/bitrev_ge0].
    + by apply/mulr_ge0; [apply addr_ge0 => //; apply/mulr_ge0 => //; move/mem_range: Hstart_range|apply/bitrev_ge0].
    move: (range_mul _ _ _ 2 _ Hx_range) => //= {Hx_range} Hx_range.
    move: (range_incl _ _ _ 0 (2 ^ (k + 1)) _ _ Hx_range) => // {Hx_range}.
    + by rewrite mulrDl /= ltzW ltzE /= exprSr //; move/mem_range: Hk_range.
    rewrite (IntID.mulrC _ 2) => Hx_range.
    congr.
    + move: (bitrev_add _ 8 _ 1 _ Hx_range) => /=.
      - by split; [apply/addr_ge0 => //|move => _; apply/ltzW/ltr_subr_addr]; move/mem_range: Hk_range => //.
      rewrite (addzC (_ * _)%Int) (addzC (bitrev _ _)%Int) bitrev1 //= => ->.
      rewrite mulrDr divz_pow //=.
      - by split; [apply/addr_ge0 => //|move => _; apply/ltzE]; move/mem_range: Hk_range => //.
      rewrite -IntID.exprD_nneg.
      - by apply/addr_ge0 => //; move/mem_range: Hk_range.
      - by apply/subr_ge0/ltzE; move/mem_range: Hk_range.
      rewrite opprD !addrA /= addrAC /= addrAC /=.
      rewrite exprD_nneg //.
      - by apply/mulr_ge0 => //; [apply/expr_ge0|apply/bitrev_ge0].
      rewrite !exp_zeta1_128 mulNr mul1r eq_sym; congr.
      apply (dvdz_exp _ _ _ _ exp_zeta1_256).
      move: (dvdz_mul (2 ^ (k + 1)) (2 ^ (7 - k)) (2 ^ (k + 1)) (bitrev 8 (2 * x))).
      rewrite -IntID.exprD_nneg.
      - by apply/addr_ge0; move/mem_range: Hk_range.
      - by apply/subr_ge0/ltzW; move/mem_range: Hk_range.
      rewrite dvdzz !addrA /= addrAC /= => -> //.
      apply bitrev_range_dvdz => //.
      - by split; [apply/subr_ge0/ltzW|move => _; apply/ler_subr_addr/ler_subl_addl/ltzW/ltzE]; move/mem_range: Hk_range.
      by rewrite opprD IntID.addrCA /= addrC.
    do 2!congr.
    move: (bitrev_add _ 8 _ 1 _ Hx_range) => /=.
    + by split; [apply/addr_ge0 => //|move => _; apply/ltzW/ltr_subr_addr]; move/mem_range: Hk_range => //.
    rewrite (addzC (_ * _)%Int) (addzC (bitrev _ _)%Int) bitrev1 //= => ->.
    rewrite divz_pow //=.
    + by split; [apply/addr_ge0 => //|move => _; apply/ltzE]; move/mem_range: Hk_range => //.
    by rewrite opprD addrA addrAC.
  qed.

  (*TODO: must be modified to account for the R * *)
  op partial_ntt (p : Fq Array256.t, len start bsj : int) =
  BAdd.bigi
    predT
    (fun s =>
      (exp zeta1 (exponent len start s)) *
      p.[index len s bsj])
    0 len.

  op partial_ntt_spec (r p : Fq Array256.t, len start bsj : int) =
    r.[index len start bsj] = partial_ntt p len start bsj.

  lemma partial_ntt_spec_k_neqxiE (r p : Fq Array256.t, k start bsj x y : int) :
    k \in range 0 7 =>
    start \in range 0 (2 ^ k) =>
    bsj \in range 0 (2 ^ (7 - k)) =>
    x \in range 0 (2 ^ k) =>
    y \in range 0 (2 ^ (8 - k)) =>
    x <> start =>
    partial_ntt_spec r p (2 ^ k) x y =>
    partial_ntt_spec
      (set2_add_mulr r (exp zeta1 (zetasctr_ntt5 (2 ^ k) start)) (index (2 ^ (k + 1)) start bsj)
         (index (2 ^ (k + 1)) (2 ^ k + start) bsj))
      p (2 ^ k) x y.
  proof.
    move => Hk_range Hstart_range Hbsj_range Hx_range Hy_range neqxstart.
    rewrite /partial_ntt_spec /= => <-.
    rewrite exprS ?mulrA; first by move/mem_range: Hk_range.
    rewrite set2_add_mulr_neqiE //.
    + rewrite index_bijective_k => //.
      - move: (range_mul_add _ 0 _ _ 2 Hbsj_range _); first by apply/mem_range.
        apply range_incl => //=.
        rewrite -exprSr; first by apply/subr_ge0/ltzW; move/mem_range: Hk_range.
        by rewrite addrAC.
      by rewrite negb_and; left.
    rewrite addrA -mulrD1l.
    rewrite index_bijective_k => //.
    + move: (range_mul_add _ 1 _ _ 2 Hbsj_range _); first by apply/mem_range.
      apply range_incl => //=.
      rewrite -exprSr; first by apply/subr_ge0/ltzW; move/mem_range: Hk_range.
      by rewrite addrAC.
    by rewrite negb_and; left.
  qed.

  lemma partial_ntt_spec_k_neqyiE (r p : Fq Array256.t, k start bsj x y : int) :
    k \in range 0 7 =>
    start \in range 0 (2 ^ k) =>
    bsj \in range 0 (2 ^ (7 - k)) =>
    x \in range 0 (2 ^ k) =>
    y \in range 0 (2 ^ (8 - k)) =>
    y <> bsj * 2 =>
    y <> bsj * 2 + 1 =>
    partial_ntt_spec r p (2 ^ k) x y =>
    partial_ntt_spec
      (set2_add_mulr r (exp zeta1 (zetasctr_ntt5 (2 ^ k) start)) (index (2 ^ (k + 1)) start bsj)
         (index (2 ^ (k + 1)) (2 ^ k + start) bsj))
      p (2 ^ k) x y.
  proof.
    move => Hk_range Hstart_range Hbsj_range Hx_range Hy_range neqybsj2 neqybsj21.
    rewrite /partial_ntt_spec /= => <-.
    rewrite exprS ?mulrA; first by move/mem_range: Hk_range.
    rewrite set2_add_mulr_neqiE //.
    + rewrite index_bijective_k => //.
      - move: (range_mul_add _ 0 _ _ 2 Hbsj_range _); first by apply/mem_range.
        apply range_incl => //=.
        rewrite -exprSr; first by apply/subr_ge0/ltzW; move/mem_range: Hk_range.
        by rewrite addrAC.
      by rewrite negb_and; right.
    rewrite addrA -mulrD1l.
    rewrite index_bijective_k => //.
    + move: (range_mul_add _ 1 _ _ 2 Hbsj_range _); first by apply/mem_range.
      apply range_incl => //=.
      rewrite -exprSr; first by apply/subr_ge0/ltzW; move/mem_range: Hk_range.
      by rewrite addrAC.
    by rewrite negb_and; right.
  qed.

  lemma partial_ntt_spec_incr_k_neqxiE (r p : Fq Array256.t, k start bsj x y : int) :
    k \in range 0 7 =>
    start \in range 0 (2 ^ k) =>
    bsj \in range 0 (2 ^ (7 - k)) =>
    x \in range 0 (2 ^ (k + 1)) =>
    y \in range 0 (2 ^ (7 - k)) =>
    x <> start =>
    x <> (2 ^ k) + start =>
    partial_ntt_spec r p (2 ^ (k + 1)) x y =>
    partial_ntt_spec
      (set2_add_mulr r (exp zeta1 (zetasctr_ntt5 (2 ^ k) start)) (index (2 ^ (k + 1)) start bsj)
         (index (2 ^ (k + 1)) (2 ^ k + start) bsj))
      p (2 ^ (k + 1)) x y.
  proof.
    move => Hk_range Hstart_range Hbsj_range Hx_range Hy_range neqxstart neqxlenstart.
    rewrite /partial_ntt_spec /= => <-.
    rewrite set2_add_mulr_neqiE //.
    + rewrite index_bijective_incr_k_start => //.
      by rewrite negb_and; left.
    rewrite index_bijective_incr_k_len_start => //.
    by rewrite negb_and; left.
  qed.

  lemma partial_ntt_spec_incr_k_neqyiE (r p : Fq Array256.t, k start bsj x y : int) :
    k \in range 0 7 =>
    start \in range 0 (2 ^ k) =>
    bsj \in range 0 (2 ^ (7 - k)) =>
    x \in range 0 (2 ^ (k + 1)) =>
    y \in range 0 (2 ^ (7 - k)) =>
    y <> bsj =>
    partial_ntt_spec r p (2 ^ (k + 1)) x y =>
    partial_ntt_spec
      (set2_add_mulr r (exp zeta1 (zetasctr_ntt5 (2 ^ k) start)) (index (2 ^ (k + 1)) start bsj)
         (index (2 ^ (k + 1)) (2 ^ k + start) bsj))
      p (2 ^ (k + 1)) x y.
  proof.
    move => Hk_range Hstart_range Hbsj_range Hx_range Hy_range neqybsj.
    rewrite /partial_ntt_spec /= => <-.
    rewrite set2_add_mulr_neqiE //.
    + rewrite index_bijective_incr_k_start => //.
      by rewrite negb_and; right.
    rewrite index_bijective_incr_k_len_start => //.
    by rewrite negb_and; right.
  qed.

  lemma IHstart_past_0 (r p : Fq Array256.t, k start bsj x y : int) :
    k \in range 0 7 =>
    start \in range 0 (2 ^ k) =>
    bsj \in range 0 (2 ^ (7 - k)) =>
    x \in range 0 start =>
    y \in range 0 (2 ^ (7 - k)) =>
    partial_ntt_spec r p (2 ^ (k + 1)) x y =>
    partial_ntt_spec
      (set2_add_mulr r (exp zeta1 (zetasctr_ntt5 (2 ^ k) start)) (index (2 ^ (k + 1)) start bsj)
         (index (2 ^ (k + 1)) (2 ^ k + start) bsj))
      p (2 ^ (k + 1)) x y.
  proof.
    move => Hk_range Hstart_range Hbsj_range Hx_range Hy_range.
    apply partial_ntt_spec_incr_k_neqxiE => //.
    + move: Hx_range; apply range_incl => //.
      apply/(lez_trans (2 ^ k)); first by apply/ltzW; move/mem_range: Hstart_range.
      apply ler_weexpn2l => //; split; first by move/mem_range: Hk_range.
      by move => _; apply/ltzW/ltzS.
    + by apply/ltr_eqF; move/mem_range: Hx_range.
    by apply/ltr_eqF/ltr_paddl; [apply expr_ge0|move/mem_range: Hx_range].
  qed.

  lemma IHstart_past_1 (r p : Fq Array256.t, k start bsj x y : int) :
    k \in range 0 7 =>
    start \in range 0 (2 ^ k) =>
    bsj \in range 0 (2 ^ (7 - k)) =>
    x \in range (2 ^ k) (2 ^ k + start) =>
    y \in range 0 (2 ^ (7 - k)) =>
    partial_ntt_spec r p (2 ^ (k + 1)) x y =>
    partial_ntt_spec
      (set2_add_mulr r (exp zeta1 (zetasctr_ntt5 (2 ^ k) start)) (index (2 ^ (k + 1)) start bsj)
         (index (2 ^ (k + 1)) (2 ^ k + start) bsj))
      p (2 ^ (k + 1)) x y.
  proof.
    move => Hk_range Hstart_range Hbsj_range Hx_range Hy_range.
    apply partial_ntt_spec_incr_k_neqxiE => //.
    + move: Hx_range; apply range_incl => //; first by apply expr_ge0.
      rewrite (addzC _ start); apply/ltzW.
      move/mem_range: (range_add _ (2 ^ k) _ _ Hstart_range) => [_].
      by rewrite addr_double -exprSr //; move/mem_range: Hk_range.
    + apply/gtr_eqF/(ltr_le_trans (2 ^ k));first by move/mem_range: Hstart_range.
      by move/mem_range: Hx_range.
    by apply/ltr_eqF; move/mem_range: Hx_range.
  qed.

  lemma IHj_past_0 (r p : Fq Array256.t, k start bsj y : int) :
    k \in range 0 7 =>
    start \in range 0 (2 ^ k) =>
    bsj \in range 0 (2 ^ (7 - k)) =>
    y \in range 0 bsj =>
    partial_ntt_spec r p (2 ^ (k + 1)) start y =>
    partial_ntt_spec
      (set2_add_mulr r (exp zeta1 (zetasctr_ntt5 (2 ^ k) start)) (index (2 ^ (k + 1)) start bsj)
         (index (2 ^ (k + 1)) (2 ^ k + start) bsj))
      p (2 ^ (k + 1)) start y.
  proof.
    move => Hk_range Hstart_range Hbsj_range Hy_range.
    apply partial_ntt_spec_incr_k_neqyiE => //.
    + move: Hstart_range; apply range_incl => //.
      apply ler_weexpn2l => //; split; first by move/mem_range: Hk_range.
      by move => _; apply/ltzW/ltzS.
    + move: Hy_range; apply range_incl => //.
      by apply/ltzW; move/mem_range: Hbsj_range.
    by apply/ltr_eqF; move/mem_range: Hy_range.
  qed.

  lemma IHj_present_0 (r p : Fq Array256.t, k start bsj : int) :
    k \in range 0 7 =>
    start \in range 0 (2 ^ k) =>
    bsj \in range 0 (2 ^ (7 - k)) =>
    partial_ntt_spec r p (2 ^ k) start (bsj * 2) =>
    partial_ntt_spec r p (2 ^ k) start (bsj * 2 + 1) =>
    partial_ntt_spec
      (set2_add_mulr r (exp zeta1 (zetasctr_ntt5 (2 ^ k) start)) (index (2 ^ (k + 1)) start bsj)
         (index (2 ^ (k + 1)) (2 ^ k + start) bsj))
      p (2 ^ (k + 1)) start bsj.
  proof.
    move => Hk_range Hstart_range Hbsj_range.
    rewrite /partial_ntt_spec /=.
    rewrite set2_add_mulr_eq1iE => //.
    + rewrite index_bijective_incr_k_len_start //.
      - move: Hstart_range; apply range_incl => //.
        apply ler_weexpn2l => //; split; first by move/mem_range: Hk_range.
        by move => _; apply/ltzW/ltzS.
      by rewrite negb_and; left; apply/ltr_eqF/ltr_spaddl => //; apply/expr_gt0.
    + by have ->:= (bitrev_range 8).
    rewrite mulrDl -!mulrA /= -addrA.
    rewrite -exprS; first by move/mem_range: Hk_range.
    move => -> ->; rewrite /partial_ntt.
    rewrite BAdd.mulr_sumr /=.
    rewrite (BAdd.big_cat_int (2 ^ k) 0 (2 ^ (k + 1))); first by apply/expr_ge0.
    + apply ler_weexpn2l => //; split; first by move/mem_range: Hk_range.
      by move => _; apply/ltzW/ltzS.
    rewrite -BAdd.mulr_sumr; congr.
    + apply BAdd.eq_big_seq => x Hx_range /=.
      rewrite -mulrA -exprS; first by move/mem_range: Hk_range.
      congr.
      by apply exponent_spec_00.
    have ->: range (2 ^ k) (2 ^ (k + 1)) = map ((+)%Int (2 ^ k)) (range 0 (2 ^ k)).
    + by rewrite -Range.range_add /= addr_double exprSr //; move/mem_range: Hk_range.
    rewrite BAdd.big_mapT BAdd.mulr_sumr; apply BAdd.eq_big_seq => x Hx_range /=.
    rewrite /(\o) /= mulrA -exprD_nneg.
    + apply/zetasctr_ntt5_ge0; first by apply/expr_ge0.
      by move/mem_range: Hstart_range.
    + by apply/exponent_ge0; move/mem_range: Hstart_range.
    rewrite !mulrDl /= -!mulrA -!addrA -!exprS.
    + by move/mem_range: Hk_range.
    congr.
    by apply exponent_spec_01.
  qed.

  lemma IHj_present_1 (r p : Fq Array256.t, k start bsj : int) :
    k \in range 0 7 =>
    start \in range 0 (2 ^ k) =>
    bsj \in range 0 (2 ^ (7 - k)) =>
    partial_ntt_spec r p (2 ^ k) start (bsj * 2) =>
    partial_ntt_spec r p (2 ^ k) start (bsj * 2 + 1) =>
    partial_ntt_spec
      (set2_add_mulr r (exp zeta1 (zetasctr_ntt5 (2 ^ k) start)) (index (2 ^ (k + 1)) start bsj)
         (index (2 ^ (k + 1)) (2 ^ k + start) bsj))
      p (2 ^ (k + 1)) (2 ^ k + start) bsj.
  proof.
    move => Hk_range Hstart_range Hbsj_range.
    rewrite /partial_ntt_spec /=.
    rewrite set2_add_mulr_eq2iE => //.
    + rewrite index_bijective_incr_k_len_start //.
      - move: Hstart_range; apply range_incl => //.
        apply ler_weexpn2l => //; split; first by move/mem_range: Hk_range.
        by move => _; apply/ltzW/ltzS.
      by rewrite negb_and; left; apply/ltr_eqF/ltr_spaddl => //; apply/expr_gt0.
    + by have ->:= (bitrev_range 8).
    rewrite mulrDl -!mulrA /= -addrA.
    rewrite -exprS; first by move/mem_range: Hk_range.
    move => -> ->; rewrite /partial_ntt.
    rewrite BAdd.mulr_sumr /= BAdd.sumrN /=.
    rewrite (BAdd.big_cat_int (2 ^ k) 0 (2 ^ (k + 1))); first by apply/expr_ge0.
    + apply ler_weexpn2l => //; split; first by move/mem_range: Hk_range.
      by move => _; apply/ltzW/ltzS.
    congr.
    + apply BAdd.eq_big_seq => x Hx_range /=.
      rewrite -mulrA -exprS; first by move/mem_range: Hk_range.
      congr.
      by apply exponent_spec_10.
    have ->: range (2 ^ k) (2 ^ (k + 1)) = map ((+)%Int (2 ^ k)) (range 0 (2 ^ k)).
    + by rewrite -Range.range_add /= addr_double exprSr //; move/mem_range: Hk_range.
    rewrite BAdd.big_mapT; apply BAdd.eq_big_seq => x Hx_range /=.
    rewrite /(\o) /= mulrA -exprD_nneg.
    + apply/zetasctr_ntt5_ge0; first by apply/expr_ge0.
      by move/mem_range: Hstart_range.
    + by apply/exponent_ge0; move/mem_range: Hstart_range.
    rewrite !mulrDl /= -!mulrA -!addrA -!exprS.
    + by move/mem_range: Hk_range.
    rewrite -mulNr.
    congr.
    rewrite -(mul1r (_ _ (_ + _)%Int)) -mulNr -exp_zeta1_128 -exprD_nneg //.
    + apply/addr_ge0.
     - apply/zetasctr_ntt5_ge0; first by apply/expr_ge0.
        by move/mem_range: Hstart_range.
      by apply/exponent_ge0; move/mem_range: Hstart_range.
    rewrite addrA.
    by apply exponent_spec_11.
  qed.

  lemma IHj_past_1 (r p : Fq Array256.t, k start bsj y : int) :
    k \in range 0 7 =>
    start \in range 0 (2 ^ k) =>
    bsj \in range 0 (2 ^ (7 - k)) =>
    y \in range 0 bsj =>
    partial_ntt_spec r p (2 ^ (k + 1)) (2 ^ k + start) y =>
    partial_ntt_spec
      (set2_add_mulr r (exp zeta1 (zetasctr_ntt5 (2 ^ k) start)) (index (2 ^ (k + 1)) start bsj)
         (index (2 ^ (k + 1)) (2 ^ k + start) bsj))
      p (2 ^ (k + 1)) (2 ^ k + start) y.
  proof.
    move => Hk_range Hstart_range Hbsj_range Hy_range.
    apply partial_ntt_spec_incr_k_neqyiE => //.
    + rewrite (addzC _ start).
      move: (range_add _ (2 ^ k) _ _ Hstart_range).
      apply range_incl => /=; first by apply expr_ge0.
      by rewrite addr_double -exprSr //; move/mem_range: Hk_range.
    + move: Hy_range; apply range_incl => //.
      by apply/ltzW; move/mem_range: Hbsj_range.
    by apply/ltr_eqF; move/mem_range: Hy_range.
  qed.

  lemma IHj_future (r p : Fq Array256.t, k start bsj y : int) :
    k \in range 0 7 =>
    start \in range 0 (2 ^ k) =>
    bsj \in range 0 (2 ^ (7 - k)) =>
    y \in range ((bsj + 1) * 2) (2 ^ (8 - k)) =>
    partial_ntt_spec r p (2 ^ k) start y =>
    partial_ntt_spec
      (set2_add_mulr r (exp zeta1 (zetasctr_ntt5 (2 ^ k) start)) (index (2 ^ (k + 1)) start bsj)
         (index (2 ^ (k + 1)) (2 ^ k + start) bsj))
    p (2 ^ k) start y.
  proof.
    move => Hk_range Hstart_range Hbsj_range Hy_range.
    apply partial_ntt_spec_k_neqyiE => //.
    + move: Hy_range; apply range_incl => //.
      apply/mulr_ge0 => //; apply/addr_ge0 => //.
      by move/mem_range: Hbsj_range.
    + apply/gtr_eqF/ltzE/ltzW/ltzE; rewrite /= -mulrD1l.
      by move/mem_range: Hy_range.
    apply/gtr_eqF/ltzE; rewrite /= -mulrD1l.
    by move/mem_range: Hy_range.
  qed.

  lemma IHstart_future (r p : Fq Array256.t, k start bsj x y : int) :
    k \in range 0 7 =>
    start \in range 0 (2 ^ k) =>
    bsj \in range 0 (2 ^ (7 - k)) =>
    x \in range (start + 1) (2 ^ k) =>
    y \in range 0 (2 ^ (8 - k)) =>
    partial_ntt_spec r p (2 ^ k) x y =>
    partial_ntt_spec
      (set2_add_mulr r (exp zeta1 (zetasctr_ntt5 (2 ^ k) start)) (index (2 ^ (k + 1)) start bsj)
         (index (2 ^ (k + 1)) (2 ^ k + start) bsj))
    p (2 ^ k) x y.
  proof.
    move => Hk_range Hstart_range Hbsj_range Hx_range Hy_range.
    apply partial_ntt_spec_k_neqxiE => //.
    + move: Hx_range; apply range_incl => //.
      apply/addr_ge0 => //.
      by move/mem_range: Hstart_range.
    apply/gtr_eqF/ltzE.
    by move/mem_range: Hx_range.
  qed.

  lemma naiventt (p : Fq Array256.t) :
      hoare
        [NTT5.ntt :
        arg = (p) ==>
        all_range_2 (partial_ntt_spec res p 128) 0 128 0 2].
  admitted. (* Broken
  proof.
    proc; sp.
    while (
      FOR_NAT_MUL_LE.inv 2 64 1 len /\
      all_range_2 (partial_ntt_spec r p len) 0 len 0 (256 %/ len)).
    + sp; wp => /=.
      while (
        FOR_INT_ADD_LT.inv 1 len 0 start /\
        all_range_2 (partial_ntt_spec r p (len * 2)) 0 start 0 (128 %/ len) /\
        all_range_2 (partial_ntt_spec r p (len * 2)) len (len + start) 0 (128 %/ len) /\
        all_range_2 (partial_ntt_spec r p len) start len 0 (256 %/ len)).
      - sp; wp.
        while (
          FOR_INT_ADD_LT.inv (len * 2) 256 0 j /\
          all_range_2 (partial_ntt_spec r p (len * 2)) 0 start 0 (128 %/ len) /\
          all_range_2 (partial_ntt_spec r p (len * 2)) len (len + start) 0 (128 %/ len) /\
          all_range (partial_ntt_spec r p (len * 2) start) 0 (j %/ (len * 2)) /\
          all_range (partial_ntt_spec r p (len * 2) (len + start)) 0 (j %/ (len * 2)) /\
          all_range (partial_ntt_spec r p len start) (j %/ len) (256 %/ len) /\
          all_range_2 (partial_ntt_spec r p len) (start + 1) len 0 (256 %/ len)).
        * sp; skip.
          (*TODO: why is the all_range_2 abbrev not abbreviating here, and why so slow for move?*)
          move => |> &hr j r.
          (*TODO: shortcut to apply this immediatly before moving into context?*)
          move => Hcond_len Hinv_len; move: (FOR_NAT_MUL_LE.inv_loopP _ _ _ _ _ Hcond_len Hinv_len) => //= [k [Hk_range ->>]].
          move => Hcond_start Hinv_start; move: (FOR_INT_ADD_LT.inv_loopP _ _ _ _ _ Hcond_start Hinv_start) => //= [start [Hstart_range ->>]].
          move => Hcond_j Hinv_j; move: (FOR_INT_ADD_LT.inv_loopP _ _ _ _ _ Hcond_j Hinv_j);
          [by rewrite //=; apply mulr_gt0 => //; apply expr_gt0|move => //= [bsj [Hbsj_range ->>]]].
          move: (FOR_INT_ADD_LT.inv_loop_post _ _ _ _ _ Hcond_j Hinv_j);
          [by rewrite //=; apply mulr_gt0 => //; apply expr_gt0|move => -> /=].
          (*TODO: shortcut to clear these when last used? List of shortcuts in EasyCrypt manual?*)
          move => {Hinv_len Hcond_len Hinv_start Hcond_start Hinv_j Hcond_j}.
          rewrite lezNgt expr_gt0 //= in Hstart_range.
          rewrite /= in Hstart_range.
          move: Hbsj_range.
          rewrite -exprSr; first by smt(mem_range).
          rewrite -!mulrD1l.
          do 2!(rewrite mulzK ?expf_eq0 //=).
          do 2!(rewrite -divzpMr; first by apply dvdz_exp2l; smt(mem_range)).
          rewrite -exprD_subz //; [by smt(mem_range)|rewrite addrAC /=].
          do 3!(rewrite divz_pow //=; first by smt(mem_range)).
          rewrite mulNr opprD /= (addzC (-k)) -!addrA.
          move => Hbsj_range Hstart_past_0 Hstart_past_1 Hj_past_0 Hj_past_1 Hj_future Hstart_future.
          rewrite all_range_min in Hj_future.
          + move: (range_mul_add _ 0 _ _ 2 Hbsj_range _); first by apply/mem_range.
            by move => /= /mem_range [_]; rewrite -exprSr /=; smt(mem_range).
          rewrite all_range_min in Hj_future.
          + move: (range_mul_add _ 1 _ _ 2 Hbsj_range _); first by apply/mem_range.
            by move => /= /mem_range [_]; rewrite -exprSr /=; smt(mem_range).
          move: Hj_future => [Hj_present_0 [Hj_present_1 Hj_future]].
          rewrite /= -mulrD1l in Hj_future.
          do!split.
          + move : Hstart_past_0.
            apply all_range_imp => y Hy_range /=; apply all_range_imp => x Hx_range /=.
            by apply IHstart_past_0.
          + move : Hstart_past_1.
            apply all_range_imp => y Hy_range /=; apply all_range_imp => x Hx_range /=.
            by apply IHstart_past_1.
          + apply all_range_max; first by apply ltzS; move/mem_range: Hbsj_range.
            split => /=.
            - move : Hj_present_0 Hj_present_1.
              by apply IHj_present_0.
            move : Hj_past_0.
            apply all_range_imp => y Hy_range /=.
            by apply IHj_past_0.
          + apply all_range_max; first by apply ltzS; move/mem_range: Hbsj_range.
            split => /=.
            - move : Hj_present_0 Hj_present_1.
              by apply IHj_present_1.
            move : Hj_past_1.
            apply all_range_imp => y Hy_range /=.
            by apply IHj_past_1.
          + move : Hj_future.
            apply all_range_imp => y Hy_range /=.
            by apply IHj_future.
          move : Hstart_future.
          apply all_range_imp => y Hy_range /=; apply all_range_imp => x Hx_range /=.
          by apply IHstart_future.
        skip.
        move => |> &hr.
        move => Hcond_len Hinv_len; move: (FOR_NAT_MUL_LE.inv_loopP _ _ _ _ _ Hcond_len Hinv_len) => //= [k [Hk_range ->>]].
        move => Hcond_start Hinv_start; move: (FOR_INT_ADD_LT.inv_loopP _ _ _ _ _ Hcond_start Hinv_start) => //= [start [Hstart_range ->>]].
        rewrite FOR_INT_ADD_LT.inv_in /=; first by rewrite //=; apply mulr_gt0 => //; apply expr_gt0.
        rewrite (FOR_INT_ADD_LT.inv_loop_post _ _ _ _ _ Hcond_start Hinv_start ) //=.
        move => {Hinv_len Hcond_len Hinv_start Hcond_start}.
        rewrite lezNgt expr_gt0 //= in Hstart_range.
        rewrite /= in Hstart_range.
        rewrite -exprSr; first by smt(mem_range).
        do 2!(rewrite divz_pow //=; first by smt(mem_range)).
        move => Hstart_past_0 Hstart_past_1 Hstart_future.
        do!split.
        * by apply all_range_empty.
        * by apply all_range_empty.
        * (*TODO: why can't I just apply the view all_range_min? Use rewrite.*)
          (*move: IHstart_future => /all_range_2_min.*)
          by move: Hstart_future; rewrite all_range_2_min /=; first by smt(mem_range).
        * by move: Hstart_future; rewrite all_range_2_min /=; first by smt(mem_range).
        move => j r.
        (*TODO: the order here seems reversed...*)
        move => {Hstart_past_0 Hstart_past_1 Hstart_future}.
        move => Hncond_j Hinv_j; move: (FOR_INT_ADD_LT.inv_outP _ _ _ _ _ Hncond_j Hinv_j);
        [by rewrite //=; apply expr_gt0|move => ->> /=].
        move => {Hncond_j Hinv_j}.
        rewrite mulzK ?expf_eq0 //=.
        rewrite -divzpMr; first by apply dvdz_exp2l; smt(mem_range).
        rewrite divz_pow //=; first by smt(mem_range).
        rewrite mulNr opprD /= (addzC (-k)).
        rewrite -exprD_subz //; [by smt(mem_range)|rewrite addrAC /=].
        rewrite -exprSr; first by smt(mem_range).
        rewrite (IntID.addrAC _ (-k)) /=.
        move => Hstart_past_0 Hstart_past_1 Hj_past_0 Hj_past_1 Hj_future Hstart_future.
        by rewrite addrA; split; apply/all_range_2_max => //=; smt(mem_range).
      skip.
      move => |> &hr.
      move => Hcond_len Hinv_len; move: (FOR_NAT_MUL_LE.inv_loopP _ _ _ _ _ Hcond_len Hinv_len) => //= [k [Hk_range ->>]].
      rewrite (FOR_NAT_MUL_LE.inv_loop_post _ _ _ _ _ Hcond_len Hinv_len) //=.
      rewrite FOR_INT_ADD_LT.inv_in //=.
      move => {Hcond_len Hinv_len}.
      rewrite -exprSr; first by smt(mem_range).
      do 3!(rewrite divz_pow //=; first by smt(mem_range)).
      rewrite opprD (addzC (-k)) /=.
      move => IHlen.
      do!split.
      - by apply all_range_2_empty.
      - by apply all_range_2_empty.
      move => r start.
      move => Hncond_start Hinv_start; move: (FOR_INT_ADD_LT.inv_outP _ _ _ _ _ Hncond_start Hinv_start) => //= ->>.
      move => {Hncond_start Hinv_start}.
      rewrite lezNgt expr_gt0 //=.
      rewrite addr_double.
      rewrite -exprSr; first by smt(mem_range).
      move => Hstart_past_0 Hstart_past_1 _.
      apply/(all_range_2_cat _ (2 ^ k)) => //.
      by rewrite expr_ge0 //= ler_weexpn2l //; smt(mem_range).
    skip.
    move => |>.
    rewrite FOR_NAT_MUL_LE.inv_in //=.
    do!split.
    + apply all_range_2_max => //=; split; last by apply all_range_2_empty.
      apply/allP => x xinrange; rewrite /partial_ntt_spec /partial_ntt /=.
      by rewrite BAdd.big_ltn // BAdd.big_geq //= addr0 exponent_0 expr0 mul1r.
    move => len r.
    by move => Hncond_len Hinv_len; move: (FOR_NAT_MUL_LE.inv_outP _ _ _ _ _ Hncond_len Hinv_len).
  qed. *)

  op update_r len start (j : int) (r : Fq Array256.t) =
    set2_add_mulr r (exp zeta1 (bitrev 8 ((256 %/ len) + (start %/ len)))) (j + start) (j + len + start).

  op update_r_j_partial len start r j =
    foldr (update_r len start) r (rev (range 0 j)).

  op update_r_j len start r =
    update_r_j_partial len start r len.

  op update_r_j_start_partial len r start =
    foldr (update_r_j len) r (rev (map (transpose ( * )%Int (len * 2)) (range 0 (start %/ (len * 2))))).

  op update_r_j_start len r =
    update_r_j_start_partial len r 256.

  op update_r_j_start_len_partial r len =
    foldr update_r_j_start r (rev (map (fun k => 2 ^ (7 - k)) (range 0 (7 - ilog 2 len)))).

  op bitrev_8_update_r len start =
    (update_r (bitrev 8 len) (bitrev 8 start)) \o (bitrev 8).

  op bitrev_8_update_r_j_partial len start r j =
    foldr (bitrev_8_update_r len start) r (rev (map (( * ) (128 %/ len)) (range 0 (j %/ (128 %/ len))))).

  op bitrev_8_update_r_j len =
    (update_r_j (bitrev 8 len)) \o (bitrev 8).

  op bitrev_8_update_r_j_start_partial len r start =
    foldr (bitrev_8_update_r_j len) r (rev (range 0 start)).

  op bitrev_8_update_r_j_start =
    update_r_j_start \o (bitrev 8).

  op bitrev_8_update_r_j_start_len_partial r len =
    foldr bitrev_8_update_r_j_start r (rev (map (fun k => 2 ^ k) (range 0 (ilog 2 len)))).

  lemma set2_add_mulr_congr r1 z1 a1 b1 r2 z2 a2 b2 :
    r1 = r2 =>
    z1 = z2 =>
    a1 = a2 =>
    b1 = b2 =>
    set2_add_mulr r1 z1 a1 b1 = set2_add_mulr r2 z2 a2 b2.
  proof. by move => |>. qed.

  lemma update_r_comm (k start1 start2 j1 j2 : int) r :
    k \in range 0 8 =>
    2 ^ (k + 1) %| start1 =>
    start1 %/ (2 ^ (k + 1)) \in range 0 (2 ^ (7 - k)) =>
    2 ^ (k + 1) %| start2 =>
    start2 %/ (2 ^ (k + 1)) \in range 0 (2 ^ (7 - k)) =>
    j1 \in range 0 (2 ^ k) =>
    j2 \in range 0 (2 ^ k) =>
    update_r (2 ^ k) start1 j1 (update_r (2 ^ k) start2 j2 r) =
    update_r (2 ^ k) start2 j2 (update_r (2 ^ k) start1 j1 r).
  proof.
    move => Hk_range Hdvd1 Hstart1_range Hdvd2 Hstart2_range Hj1_range Hj2_range.
    case (j1 + start1 = j2 + start2) => [Heq|Hneq].
    + move: (congr1 (transpose (%%) (2 ^ (k + 1))) _ _ Heq) => /=.
      rewrite !dvdz_modzDr // !modz_small ?ger0_norm ?expr_ge0 // -?mem_range.
      - move: Hj1_range; apply mem_range_incl => //; apply ler_weexpn2l => //.
        by move /mem_range: Hk_range => [-> _ /=]; rewrite lez_addl.
      - move: Hj2_range; apply mem_range_incl => //; apply ler_weexpn2l => //.
        by move /mem_range: Hk_range => [-> _ /=]; rewrite lez_addl.
      move => ->>; move: (congr1 ((transpose ( * )%Int (2 ^ (k + 1))) \o (transpose (%/) (2 ^ (k + 1)))) _ _ Heq) => /=.
      rewrite /(\o) /= !divzDr // !mulrDl (divzK _ start1) // (divzK _ start2) // !divz_small ?ger0_norm ?expr_ge0 // -?mem_range.
      move: Hj2_range; apply mem_range_incl => //; apply ler_weexpn2l => //.
      by move /mem_range: Hk_range => [-> _ /=]; rewrite lez_addl.
    have Hneq1: j1 + start1 <> j2 + start2 + (2 ^ k).
    + apply/negP => /(congr1 (transpose (%%) (2 ^ (k + 1))) _ _) => /=.
      rewrite addrAC dvdz_modzDr // dvdz_modzDr // !modz_small ?ger0_norm ?expr_ge0 // -?mem_range.
      - move: Hj1_range; apply mem_range_incl => //; apply ler_weexpn2l => //.
        by move /mem_range: Hk_range => [-> _ /=]; rewrite lez_addl.
      - rewrite mem_range_addr; move: Hj2_range; apply/mem_range_incl => //=; first by rewrite ler_oppl /= expr_ge0.
        rewrite exprD_nneg //; first by move/mem_range: Hk_range.
        by rewrite expr1 -addr_double -addrA.
      apply/negP => /(congr1 (transpose (%/) (2 ^ k)) _ _) => /=.
      rewrite divzDr ?dvdzz // divzz !divz_small ?ger0_norm ?expr_ge0 // -?mem_range //=.
      by rewrite (neq_ltz _ 0) expr_gt0.
    have Hneq2: j1 + start1 + (2 ^ k) <> j2 + start2.
    + apply/negP => /(congr1 (transpose (%%) (2 ^ (k + 1))) _ _) => /=.
      rewrite addrAC dvdz_modzDr // (dvdz_modzDr j2) // !modz_small ?ger0_norm ?expr_ge0 // -?mem_range.
      - rewrite mem_range_addr; move: Hj1_range; apply/mem_range_incl => //=; first by rewrite ler_oppl /= expr_ge0.
        rewrite exprD_nneg //; first by move/mem_range: Hk_range.
        by rewrite expr1 -addr_double -addrA.
      - move: Hj2_range; apply mem_range_incl => //; apply ler_weexpn2l => //.
        by move /mem_range: Hk_range => [-> _ /=]; rewrite lez_addl.
      apply/negP => /(congr1 (transpose (%/) (2 ^ k)) _ _) => /=.
      rewrite divzDr ?dvdzz // divzz !divz_small ?ger0_norm ?expr_ge0 // -?mem_range //=.
      by rewrite (neq_ltz (_ ^ _)%IntID) expr_gt0.
    have Hneq12: j1 + start1 + (2 ^ k) <> j2 + start2 + (2 ^ k).
    + by apply/negP => /addIz.
    have H1_range: j1 + start1 \in range 0 256.
    + move: (mem_range_add_mul _ _ (2 ^ (k + 1)) j1 _ _ Hstart1_range) => /=.
      - move: Hj1_range; apply/mem_range_incl => //; apply ler_weexpn2l => //.
        by move /mem_range: Hk_range => [-> _ /=]; rewrite lez_addl.
      rewrite -exprD_nneg.
      - by apply/subr_ge0/ltzS; move/mem_range: Hk_range.
      - by apply/addr_ge0 => //; move/mem_range: Hk_range.
      by rewrite (mulzC (_ ^ _)%IntID) addrA -(addzA 7) /= divzK.
    have H1l_range: j1 + start1 + (2 ^ k) \in range 0 256.
    + move: (mem_range_add_mul _ _ (2 ^ (k + 1)) (j1 + (2 ^ k)) _ _ Hstart1_range) => /=.
      - rewrite mem_range_addr; move: Hj1_range; apply/mem_range_incl => //=; first by rewrite ler_oppl /= expr_ge0.
        rewrite exprD_nneg //; first by move/mem_range: Hk_range.
        by rewrite expr1 -addr_double -addrA.
      rewrite -exprD_nneg.
      - by apply/subr_ge0/ltzS; move/mem_range: Hk_range.
      - by apply/addr_ge0 => //; move/mem_range: Hk_range.
      by rewrite (mulzC (_ ^ _)%IntID) addrA -(addzA 7) /= divzK // addrAC.
    have H2_range: j2 + start2 \in range 0 256.
    + move: (mem_range_add_mul _ _ (2 ^ (k + 1)) j2 _ _ Hstart2_range) => /=.
      - move: Hj2_range; apply/mem_range_incl => //; apply ler_weexpn2l => //.
        by move /mem_range: Hk_range => [-> _ /=]; rewrite lez_addl.
      rewrite -exprD_nneg.
      - by apply/subr_ge0/ltzS; move/mem_range: Hk_range.
      - by apply/addr_ge0 => //; move/mem_range: Hk_range.
      by rewrite (mulzC (_ ^ _)%IntID) addrA -(addzA 7) /= divzK.
    have H2l_range: j2 + start2 + (2 ^ k) \in range 0 256.
    + move: (mem_range_add_mul _ _ (2 ^ (k + 1)) (j2 + (2 ^ k)) _ _ Hstart2_range) => /=.
      - rewrite mem_range_addr; move: Hj2_range; apply/mem_range_incl => //=; first by rewrite ler_oppl /= expr_ge0.
        rewrite exprD_nneg //; first by move/mem_range: Hk_range.
        by rewrite expr1 -addr_double -addrA.
      rewrite -exprD_nneg.
      - by apply/subr_ge0/ltzS; move/mem_range: Hk_range.
      - by apply/addr_ge0 => //; move/mem_range: Hk_range.
      by rewrite (mulzC (_ ^ _)%IntID) addrA -(addzA 7) /= divzK // addrAC.
    have Hneqp: forall y , y <> y + (2 ^ k).
    + by move => y; rewrite ltr_eqF // ltr_addl expr_gt0.
    have Hneqn: forall y , y - (2 ^ k) <> y.
    + by move => y; rewrite ltr_eqF // ltr_subl_addr ltr_addl expr_gt0.
    have Hneqpn: forall y , y - (2 ^ k) <> y + (2 ^ k).
    + by move => y; rewrite ltr_eqF // ltr_subl_addr -addrA ltr_addl addr_gt0 expr_gt0.
    apply/Array256.ext_eq => x /mem_range Hx_range; rewrite /update_r !(addzAC _ (2 ^ k)).
    move => {Hk_range Hdvd1 Hdvd2 Hstart1_range Hstart2_range Hj1_range Hj2_range}.
    move: Hneq Hneq1 Hneq2 Hneq12 H1_range H1l_range H2_range H2l_range.
    case  (j1 + start1 = x) => [->|Hneqx1]; [|case (j1 + start1 = x - (2 ^ k)) => [->|Hneqxl1]];
    (case (j2 + start2 = x) => [->|Hneqx2]; [|case (j2 + start2 = x - (2 ^ k)) => [->|Hneqxl2]]);
    rewrite ?subrK //; move => Hneq Hneq1 Hneq2 Hneq12 H1_range H1l_range H2_range H2l_range.
    + rewrite set2_add_mulr_eq1iE ?Hneqp //.
      rewrite set2_add_mulr_neqiE ?Heq //.
      rewrite set2_add_mulr_neqiE //.
      rewrite set2_add_mulr_neqiE //.
      by rewrite set2_add_mulr_eq1iE ?Hneqp.
    + rewrite set2_add_mulr_eq2iE ?Hneqn //.
      rewrite set2_add_mulr_neqiE //.
      rewrite set2_add_mulr_neqiE //.
      rewrite set2_add_mulr_neqiE //.
      by rewrite set2_add_mulr_eq2iE ?Hneqn.
    + rewrite set2_add_mulr_neqiE //; first 2 by rewrite eq_sym.
      rewrite set2_add_mulr_eq1iE ?Hneqp //.
      rewrite set2_add_mulr_eq1iE ?Hneqp //.
      rewrite set2_add_mulr_neqiE //; first 2 by rewrite eq_sym.
      by rewrite set2_add_mulr_neqiE //; rewrite eq_sym.
    + rewrite set2_add_mulr_neqiE //; first 2 by rewrite eq_sym.
      rewrite set2_add_mulr_eq2iE ?Hneqn //.
      rewrite set2_add_mulr_eq2iE ?Hneqn //.
      rewrite set2_add_mulr_neqiE //; first 2 by rewrite eq_sym.
      by rewrite set2_add_mulr_neqiE //; rewrite eq_sym.
    rewrite set2_add_mulr_neqiE //; first 2 rewrite eq_sym //.
    + by move: Hneqxl1; rewrite implybNN => <-; rewrite -!(addrA).
    rewrite set2_add_mulr_neqiE //; first 2 rewrite eq_sym //.
    + by move: Hneqxl2; rewrite implybNN => <-; rewrite -!(addrA).
    rewrite set2_add_mulr_neqiE //; first 2 rewrite eq_sym //.
    + by move: Hneqxl2; rewrite implybNN => <-; rewrite -!(addrA).
    rewrite set2_add_mulr_neqiE // eq_sym //.
    by move: Hneqxl1; rewrite implybNN => <-; rewrite -!(addrA).
  qed.

  lemma update_r_j_comm (k start1 start2 : int) r :
    k \in range 0 8 =>
    2 ^ (k + 1) %| start1 =>
    start1 %/ (2 ^ (k + 1)) \in range 0 (2 ^ (7 - k)) =>
    2 ^ (k + 1) %| start2 =>
    start2 %/ (2 ^ (k + 1)) \in range 0 (2 ^ (7 - k)) =>
    update_r_j (2 ^ k) start1 (update_r_j (2 ^ k) start2 r) =
    update_r_j (2 ^ k) start2 (update_r_j (2 ^ k) start1 r).
  proof.
    move => Hk_range Hdvd1 Hstart1_range Hdvd2 Hstart2_range.
    rewrite /update_r_j /update_r_j_partial.
    rewrite !(foldr_zip_nseq (update_r (2 ^ k))) -!foldr_cat.
    apply foldr_perm_in; last by apply perm_catC.
    rewrite -!zip_cat; first by rewrite size_nseq ler_maxr // size_ge0.
    move => p [startx jx] [starty jy] /mem_zip Hp_range /mem_zip; move: Hp_range.
    rewrite !mem_cat !mem_nseq !size_rev !size_range !ler_maxr /= ?expr_ge0 //.
    rewrite !expr_gt0 //=; rewrite !(orb_idl (_ \in _)) // !mem_rev.
    by move => |> [->>|->>] Hjx_range [->>|->>] Hjy_range; rewrite update_r_comm.
  qed.

  equiv eq_NTT4_NTT5 p : NTT4.ntt ~ NTT5.ntt:
    arg{1} = p /\ arg{2} = p ==> ={res}.
  proof.
    proc; sp.
    while (
      FOLDR_RHL_FOR_NAT_DIV_GE_MUL_LE.inv
        update_r_j_start          p r{1} 2 2 128 len{1}
        bitrev_8_update_r_j_start p r{2} 2   1   len{2}
      ).
    + sp; wp => /=.
      while (
        2 <= len{1} /\
        len{2} <= 64 /\
        FOLDR_RHL_FOR_NAT_DIV_GE_MUL_LE.inv
          update_r_j_start          p (update_r_j_start_len_partial p len{1})          2 2 128 len{1}
          bitrev_8_update_r_j_start p (bitrev_8_update_r_j_start_len_partial p len{2}) 2   1   len{2} /\
        FOLDR_RHL_FOR_INT_ADD_LT2.inv
          (update_r_j len{1})          (update_r_j_start_len_partial p len{1})          r{1} (len{1} * 2) 256 0 start{1}
          (bitrev_8_update_r_j len{2}) (bitrev_8_update_r_j_start_len_partial p len{2}) r{2} 1                0 start{2}
        ).
      - sp; wp => /=.
        while (
          2 <= len{1} /\
          len{2} <= 64 /\
          FOLDR_RHL_FOR_NAT_DIV_GE_MUL_LE.inv
            update_r_j_start          p (update_r_j_start_len_partial p len{1})          2 2 128 len{1}
            bitrev_8_update_r_j_start p (bitrev_8_update_r_j_start_len_partial p len{2}) 2   1   len{2} /\
          start{1} < 256 /\
          start{2} < len{2} /\
          FOLDR_RHL_FOR_INT_ADD_LT2.inv
            (update_r_j len{1})
            (update_r_j_start_len_partial p len{1})
            (update_r_j_start_partial len{1} (update_r_j_start_len_partial p len{1}) start{1})
            (len{1} * 2) 256 0 start{1}
            (bitrev_8_update_r_j len{2})
            (bitrev_8_update_r_j_start_len_partial p len{2})
            (bitrev_8_update_r_j_start_partial len{2} (bitrev_8_update_r_j_start_len_partial p len{2}) start{2})
            1                0 start{2} /\
          FOLDR_RHL_FOR_INT_ADD_LT2.inv
            (update_r len{1} start{1})
            (update_r_j_start_partial len{1} (update_r_j_start_len_partial p len{1}) start{1})
            r{1}
            1            len{1} 0 j{1}
            (bitrev_8_update_r len{2} start{2})
            (bitrev_8_update_r_j_start_partial len{2} (bitrev_8_update_r_j_start_len_partial p len{2}) start{2})
            r{2}
            (len{2} * 2)        0 j{2} /\
          zetasctr{1} = bitrev 8 (256 %/ len{1} + start{1} %/ len{1}) /\
          zeta_{1} = exp zeta1 zetasctr{1} /\
          zetasctr{2} = zetasctr_ntt5 len{2} start{2} /\
          zeta_{2} = exp zeta1 zetasctr{2}
          ).
        * sp; skip => |> &hr1 &hr2 j2 r2 j1 r1.
          move => Hcond_len1 Hcond_len2 Hinv_len.
          move: (FOLDR_RHL_FOR_NAT_DIV_GE_MUL_LE.inv_loopP _ _ _ _ _ _ _ _ _ _ _ _ _ _
                  _ _ Hcond_len1 Hcond_len2 Hinv_len) => //.
          move => [k /= [Hk_range [->> [->> _]]]].
          move => {Hcond_len1 Hcond_len2 Hinv_len}.
          move => Hcond_start1 Hcond_start2 Hinv_start.
          move: (FOLDR_RHL_FOR_INT_ADD_LT2.inv_loopP _ _ _ _ _ _ _ _ _ _ _ _ _ _
                  _ _ Hcond_start1 Hcond_start2 Hinv_start) => //.
          + rewrite /= divz_pow //=; first by move/mem_range: Hk_range => [-> /=]; apply/ltzW.
            rewrite -exprSr /=; first by apply/subr_ge0/ltzW; move/mem_range: Hk_range.
            by apply/expr_gt0.
          move => [s /= [Hs_range [->> [->> _]]]].
          rewrite divz_pow //= in Hs_range; first by move/mem_range: Hk_range => [-> /=]; apply/ltzW.
          rewrite /= -exprSr /= in Hs_range; first by apply/subr_ge0/ltzW; move/mem_range: Hk_range.
          rewrite divz_pow /= // in Hs_range.
          + rewrite subr_ge0 ler_subl_addr -ler_subl_addl /=; move/mem_range: Hk_range => [-> /=].
            by move => ltk7; apply/ltzS/(ltr_le_trans 7).
          rewrite opprD /= mulNr mul1r opprK in Hs_range.
          move => {Hcond_start1 Hcond_start2 Hinv_start}.
          move => Hinv_j Hcond_j1 Hcond_j2.
          move: (FOLDR_RHL_FOR_INT_ADD_LT2.inv_loop_post _ _ _ _ _ _ _ _ _ _ _ _ _ _
                  _ _ Hcond_j1 Hcond_j2 Hinv_j) => //; [|move => Hinv_j_post].
          + rewrite /= -exprSr; first by move/mem_range: Hk_range.
            by apply/expr_gt0.
          move: (FOLDR_RHL_FOR_INT_ADD_LT2.inv_loopP _ _ _ _ _ _ _ _ _ _ _ _ _ _
                  _ _ Hcond_j1 Hcond_j2 Hinv_j) => //.
          + rewrite /= -exprSr; first by move/mem_range: Hk_range.
            by apply/expr_gt0.
          move => [j /= [Hj_range [->> [->> _]]]].
          rewrite divz_pow // /= in Hj_range; first by move/mem_range: Hk_range => [-> /=]; apply/ltzW.
          rewrite lezNgt expr_gt0 // /= in Hj_range.
          move => {Hinv_j Hcond_j1 Hcond_j2}.
          split.
          + move: Hinv_j_post; apply/iffLR/eq_iff; congr; rewrite /update_r /idfun /zetasctr_ntt5 //=.
            rewrite -exprSr; first by move/mem_range: Hk_range.
            apply set2_add_mulr_congr => //.
            - congr; rewrite !bitrev_pow2 /=; first by move: Hk_range; apply range_incl.
              rewrite divz_pow //=.
              * rewrite ler_subr_addr /= -ler_subr_addr opprK -ler_subl_addl /=.
                by move/mem_range: Hk_range => [? ?]; split => [|_]; [apply/ltzW|apply/ltzW/ltzE].
              rewrite opprD /= (addzC 1) (addzC (_ ^ _)%IntID) -(mulz1 (2 ^ (k + 1))) bitrev_add.
              * by move/mem_range: Hk_range => [? ?]; split => [|_]; [apply/addr_ge0|apply/ltzW/ltr_subr_addr].
              * rewrite range_div_range ?expr_gt0 //=; move/mem_range: Hk_range => [? ?].
                rewrite -exprD_nneg //; [by apply/addr_ge0|by apply/subr_ge0/ltzW| ].
                by rewrite !addrA /= addrAC /=; apply/(bitrev_range 8).
              rewrite bitrev1 //= bitrev_divr_pow2.
              * move/mem_range: Hk_range => [? ?]; rewrite subr_ge0 -ler_subr_addr opprK -ler_subl_addl /=.
                by split => [|_]; [apply/ltzW|apply/ltzW/ltzE].
              rewrite bitrev2_ge /=; first by rewrite ler_subr_addr -ler_subr_addl ltzW; move/mem_range: Hk_range.
              rewrite (modz_small s).
              * rewrite -mem_range; move: Hs_range; apply/mem_range_incl => //.
                move: (ler_weexpn2l 2 _ k 8) => // ->; move/mem_range: Hk_range => [? ?] //.
                by split => // _; apply/ltzW/ltzE/ltzW/ltr_subr_addr.
              rewrite modz_small.
              * rewrite -mem_range mem_range_mull ?expr_gt0 //=; move: Hs_range; apply/mem_range_incl => //.
                rewrite divz_pow //=.
                + rewrite subr_ge0 -ler_subr_addr opprK -ler_subl_addl; move/mem_range: Hk_range => [? ?].
                  split => [|_]; [by apply/ltzW|].
                  (*TODO: why do I have to do this? hint simplify seems to have a max depth?*)
                  do 8!(rewrite vp_dvd //=); rewrite vp0 //=.
                  by apply/ltzW/ltzE.
                do 8!(rewrite vp_dvd //=); rewrite vp0 //=; rewrite opprD /CoreInt.absz /= mulNr /=.
                by apply/ler_weexpn2l => //; move/mem_range: Hk_range => [-> _]; rewrite ler_paddl.
              rewrite divz_pow //=; first by rewrite -ltzE; move/mem_range: Hk_range => [? -> /=]; apply/addr_ge0.
              rewrite opprD addrA addrAC /= divz_pow //=; first by rewrite -(ltzS k 6) -mem_range.
              rewrite mulrDl /= -mulrA -exprS; first by apply/subr_ge0/ltzS; move/mem_range: Hk_range.
              by rewrite addrAC /= mulrC.
            - rewrite (addzC (_ * _)%Int) mulrC bitrev_add.
              * by move/mem_range: Hk_range => [? ?]; split => [|_]; [apply/addr_ge0|apply/ltzW/ltr_subr_addr].
              * move: Hs_range; apply/mem_range_incl => //.
                by apply/ler_weexpn2l => //; move/mem_range: Hk_range => [-> _]; rewrite ler_paddr.
              rewrite addrC bitrev_mulr_pow2 //.
              by move/mem_range: Hk_range => [? ?]; split => [|_]; [apply/addr_ge0|apply/ltzW/ltr_subr_addr].
            rewrite -!addrA (addzC (_ * _)%Int) mulrC bitrev_add.
            - by move/mem_range: Hk_range => [? ?]; split => [|_]; [apply/addr_ge0|apply/ltzW/ltr_subr_addr].
            - rewrite mem_range_addl; move: Hs_range; apply/mem_range_incl => //; first by rewrite /= oppr_le0 expr_ge0.
              rewrite exprSr; first by move/mem_range: Hk_range.
              by rewrite -addr_double -addrA.
            rewrite addrC bitrev_mulr_pow2.
            - by move/mem_range: Hk_range => [? ?]; split => [|_]; [apply/addr_ge0|apply/ltzW/ltr_subr_addr].
            congr; rewrite (addzC _ s) -(mulz1 (2 ^ k)) bitrev_add //.
            - by move/mem_range: Hk_range => [-> ? /=]; apply/ltzW/ltzE/ltzW/ltr_subr_addr.
            rewrite bitrev1 //= bitrev_pow2 /=; first by move: Hk_range; apply/mem_range_incl.
            by rewrite addrC divz_pow //=; move/mem_range: Hk_range => [-> ? /=]; apply/ltzW.
          apply/iffE => {Hinv_j_post}.
          rewrite -exprSr; first by move/mem_range: Hk_range.
          rewrite -mulrD1l -ltz_NdivNLR; first by apply/expr_gt0.
          rewrite divz_pow //=; first by move/mem_range: Hk_range => [-> /=]; apply/ltzW.
          rewrite divz_pow //=; first by move/mem_range: Hk_range => [? ?]; split => [|_]; [apply/addr_ge0|apply/ltzW/ltr_subr_addr].
          by rewrite mulNr mul1r opprK opprD /= (addzC (-k)).
        skip => |> &hr1 &hr2.
        move => Hcond_len1 Hcond_len2 Hinv_len.
        move: (FOLDR_RHL_FOR_NAT_DIV_GE_MUL_LE.inv_loopP _ _ _ _ _ _ _ _ _ _ _ _ _ _
                _ _ Hcond_len1 Hcond_len2 Hinv_len) => //.
        move => [k /= [Hk_range [->> [->> _]]]].
        move => {Hcond_len1 Hcond_len2 Hinv_len}.
        move => Hinv_start Hcond_start1 Hcond_start2.
        move: (FOLDR_RHL_FOR_INT_ADD_LT2.inv_loopP _ _ _ _ _ _ _ _ _ _ _ _ _ _
                _ _ Hcond_start1 Hcond_start2 Hinv_start) => //.
        * rewrite /= divz_pow //=; first by move/mem_range: Hk_range => [-> /=]; apply/ltzW.
          rewrite -exprSr /=; first by apply/subr_ge0/ltzW; move/mem_range: Hk_range.
          by apply/expr_gt0.
        move => [s /= [Hs_range [->> [->> [->> ->>]]]]].
        rewrite divz_pow // /= in Hs_range; first by move/mem_range: Hk_range => [-> /=]; apply/ltzW.
        rewrite -exprSr /= in Hs_range; first by apply/subr_ge0/ltzW; move/mem_range: Hk_range.
        rewrite divz_pow /= // in Hs_range.
        * rewrite subr_ge0 ler_subl_addr -ler_subl_addl /=; move/mem_range: Hk_range => [-> /=].
          by move => ltk7; apply/ltzS/(ltr_le_trans 7).
        rewrite opprD /= mulNr mul1r opprK in Hs_range.
        rewrite /update_r_j_start_partial /bitrev_8_update_r_j_start_partial map_id mulzK.
        * apply/gtr_eqF; rewrite divz_pow //=; first by move/mem_range: Hk_range => [-> ? /=]; apply/ltzW.
          by apply/mulr_gt0 => //; apply/expr_gt0.
        rewrite FOLDR_RHL_FOR_INT_ADD_LT2.inv_in //=.
        do!split.
        * by move: Hinv_start; rewrite map_id.
        * by rewrite divz_pow //=; [move/mem_range: Hk_range => [-> ? /=]; apply/ltzW|apply/expr_gt0].
        move => j1 r1 j2 r2 Hncond_j1 Hncond_j2 {Hinv_start} Hinv_start Hinv_j.
        move: (FOLDR_RHL_FOR_INT_ADD_LT2.inv_loop_post _ _ _ _ _ _ _ _ _ _ _ _ _ _
                _ _ Hcond_start1 Hcond_start2 Hinv_start) => //.
        * rewrite /= divz_pow //=; first by move/mem_range: Hk_range => [-> /=]; apply/ltzW.
          rewrite -exprSr /=; first by apply/subr_ge0/ltzW; move/mem_range: Hk_range.
          by apply/expr_gt0.
        move => {Hcond_start1 Hcond_start2 Hinv_start}.
        move: (FOLDR_RHL_FOR_INT_ADD_LT2.inv_outP _ _ _ _ _ _ _ _ _ _ _ 256 _ _
                _ _ _ Hncond_j1 Hinv_j) => //=.
        * rewrite lezNgt divz_pow //=; first by move/mem_range: Hk_range => [-> ? /=]; apply/ltzW.
          rewrite -exprSr; first by move/mem_range: Hk_range.
          rewrite divz_pow //=; first by move/mem_range: Hk_range => [? ?]; split => [|_]; [apply/addr_ge0|apply/ltzW/ltr_subr_addr].
          pose P := (0 < _); have ->/=: P.
          + by rewrite /P expr_gt0.
          by rewrite mulNr opprK mul1r opprD addrA addrAC.
        * by rewrite /= mulr_gt0 // expr_gt0.
        move => |> {Hncond_j1 Hncond_j2 Hinv_j}.
        rewrite map_id lezNgt.
        pose P := (0 < _); have ->/={P}: P.
        * rewrite /P divz_pow //=; first by move/mem_range: Hk_range => [-> ? /=]; apply/ltzW.
          by apply/expr_gt0.
        move => Hinv_start_post; split.
        * move: Hinv_start_post.
          pose Hinv1:= (FOLDR_RHL_FOR_INT_ADD_LT2.inv _ _ _ _ _ _ _ _ _ _ _ _ _).
          pose Hinv2:= (FOLDR_RHL_FOR_INT_ADD_LT2.inv _ _ _ _ _ _ _ _ _ _ _ _ _).
          rewrite -(eqT Hinv1) -(eqT Hinv2) /Hinv1 /Hinv2 => <- {Hinv1 Hinv2}; congr => //.
          rewrite /bitrev_8_update_r_j {2}/(\o) {2}/update_r_j /update_r_j_partial.
          rewrite /bitrev_8_update_r foldr_comp.
          rewrite -exprSr; first by move/mem_range: Hk_range.
          rewrite divz_pow //=.
          + by move/mem_range: Hk_range => [? ?]; split => [|_]; [apply addr_ge0|apply/ltzW/ltr_subr_addr].
          rewrite opprD /= (addzC (-k)) mulNr mul1r opprK map_rev -map_comp bitrev_pow2 /=.
          + by move: Hk_range; apply/mem_range_incl.
          apply foldr_perm_in.
          + move => r ? ?; rewrite !mem_rev => /mapP [x [Hx_range ->>]] /mapP [y [Hy_range ->>]].
            apply update_r_comm => //.
            - by rewrite mem_range_subl /=; move: Hk_range; apply/mem_range_incl.
            - rewrite addrAC /= bitrev_range_dvdz ?opprD //.
              rewrite subr_ge0 -ler_subr_addr opprK -ler_subl_addl.
              by move/mem_range: Hk_range => [-> ? /=]; apply/ltzW/ltzE/ltzW/ltr_subr_addr.
            - rewrite opprD /= range_div_range /=; first by apply/expr_gt0.
              rewrite -exprD_nneg; first by move/mem_range: Hk_range.
              * by apply/subr_ge0/ltzW/ltzE/ltzW/ltr_subr_addr; move/mem_range: Hk_range.
              by rewrite addrA addrAC /= (bitrev_range 8).
            - rewrite addrAC /= bitrev_range_dvdz ?opprD //.
              rewrite subr_ge0 -ler_subr_addr opprK -ler_subl_addl.
              by move/mem_range: Hk_range => [-> ? /=]; apply/ltzW/ltzE/ltzW/ltr_subr_addr.
            - rewrite opprD /= range_div_range /=; first by apply/expr_gt0.
              rewrite -exprD_nneg; first by move/mem_range: Hk_range.
              * by apply/subr_ge0/ltzW/ltzE/ltzW/ltr_subr_addr; move/mem_range: Hk_range.
              by rewrite addrA addrAC /= (bitrev_range 8).
            - rewrite /(\o) /= mulrC bitrev_mulr_pow2.
              * by move/mem_range: Hk_range => [? ?]; rewrite addr_ge0 //= ltzW -ltr_subr_addr.
              rewrite range_div_range; first by apply/expr_gt0.
              rewrite -exprD_nneg /=.
              * by rewrite subr_ge0 ltzW; move/mem_range: Hk_range.
              * by rewrite addr_ge0; move/mem_range: Hk_range.
              by rewrite addrA -(addzA 7) /= (bitrev_range 8).
            rewrite /(\o) /= mulrC bitrev_mulr_pow2.
            - by move/mem_range: Hk_range => [? ?]; rewrite addr_ge0 //= ltzW -ltr_subr_addr.
            rewrite range_div_range; first by apply/expr_gt0.
            rewrite -exprD_nneg /=.
            - by rewrite subr_ge0 ltzW; move/mem_range: Hk_range.
            - by rewrite addr_ge0; move/mem_range: Hk_range.
            by rewrite addrA -(addzA 7) /= (bitrev_range 8).
          rewrite (perm_eq_trans _ _ _ _ (perm_eq_rev (range 0 (2 ^ (7 - k))))) perm_eq_sym.
          rewrite (perm_eq_trans _ _ _ _ (perm_eq_rev (map (bitrev 8 \o transpose Int.( * ) (2 ^ (k + 1))) (range 0 (2 ^ (7 - k)))))).
          rewrite perm_eq_sym.
          move: (eq_in_map (bitrev 8 \o transpose Int.( * ) (2 ^ (k + 1))) (bitrev 8 \o ( * ) (2 ^ (k + 1))) (range 0 (2 ^ (7 - k)))).
          move => [Heq_map _]; move: Heq_map => -> => [x Hx_range|]; first by rewrite /(\o) /= mulrC.
          rewrite (perm_eq_trans _ _ _ (bitrev_mul_range_pow2_perm_eq (7 - k) (k + 1) 8 _ _ _)).
          + by apply/subr_ge0/ltzW; move/mem_range: Hk_range.
          + by apply/addr_ge0 => //; move/mem_range: Hk_range.
          + by rewrite addrA -(addzA 7).
          by rewrite !opprD opprK !addrA /= -(addzA 1) /= (eq_map _ idfun) // map_id perm_eq_refl.
        apply/iffE => {Hinv_start_post}.
        rewrite divz_pow //=; first by move/mem_range: Hk_range => [-> /=]; apply/ltzW.
        rewrite -exprSr; first by apply/subr_ge0/ltzW; move/mem_range: Hk_range.
        rewrite addrAC /= -mulrD1l -ltz_NdivNLR; first by apply/expr_gt0.
        rewrite divz_pow //=.
        * move/mem_range: Hk_range => [? ?]; split => [|_]; first by apply/subr_ge0/ltzW/ltzE/ltzW/ltr_subr_addr.
          by rewrite -ler_subr_addr opprK -ler_subl_addl.
        by rewrite mulNr mul1r opprK opprD.
      skip => |> &hr1 &hr2.
      move => Hinv_len Hcond_len1 Hcond_len2.
      move: (FOLDR_RHL_FOR_NAT_DIV_GE_MUL_LE.inv_loopP _ _ _ _ _ _ _ _ _ _ _ _ _ _
              _ _ Hcond_len1 Hcond_len2 Hinv_len) => //.
      move => [k /= [Hk_range [->> [->> [->> ->>]]]]].
      move: (FOLDR_RHL_FOR_NAT_DIV_GE_MUL_LE.inv_loop_post _ _ _ _ _ _ _ _ _ _ _ _ _ _
              _ _ Hcond_len1 Hcond_len2 Hinv_len) => //.
      move => {Hcond_len1 Hcond_len2}.
      move: Hinv_len.
      rewrite /update_r_j_start_len_partial /bitrev_8_update_r_j_start_len_partial /bitrev_8_update_r_j_start.
      rewrite expr_gt0 //= foldr_comp divz_pow //=; first by move/mem_range: Hk_range => [-> ? /=]; apply/ltzW.
      rewrite !ilog_powK //; [by apply/subr_ge0/ltzW; move/mem_range: Hk_range|by move/mem_range: Hk_range| ].
      rewrite opprD /= foldr_comp !map_rev -!map_comp.
      move: (eq_in_map (fun (n : int) => 128 %/ 2 ^ n) (fun (n : int) => 2 ^ (7 - n)) (range 0 k)) => [->]; [|move => _].
      - move => x Hx_range /=; rewrite divz_pow //=; move/mem_range: Hx_range => [-> ? /=].
        by apply/ltzW/(ltz_trans k) => //; move/mem_range: Hk_range.
      move: (eq_in_map (bitrev 8 \o (^) 2) (fun (n : int) => 2 ^ (7 - n)) (range 0 k)) => [->]; [|move => _].
      - move => x Hx_range /=; rewrite /(\o) /= bitrev_pow2 //; move: Hx_range; apply/mem_range_incl => //.
        by apply/ltzW/ltzE/ltzW/ltr_subr_addr; move/mem_range: Hk_range.
      move => -> Hinv_len_post /=; rewrite FOLDR_RHL_FOR_INT_ADD_LT2.inv_in /=.
      - by apply/mulr_gt0 => //; apply/expr_gt0.
      move => r1 start1 r2 start2.
      move => Hncond_start1 Hncond_start2 Hinv_start.
      move: (FOLDR_RHL_FOR_INT_ADD_LT2.inv_outP _ _ _ _ _ _ _ _ _ _ _ (2 ^ k) _ _
              _ _ _ Hncond_start1 Hinv_start) => //=.
      - rewrite lezNgt expr_gt0 //= -exprSr; first by apply/subr_ge0/ltzW; move/mem_range: Hk_range.
        rewrite addrAC /= divz_pow //=.
        * rewrite subr_ge0 -ler_subr_addr opprK -ler_subl_addl /=.
          by move/mem_range: Hk_range => [-> ? /=]; apply/ltzW/ltzE/ltzW/ltr_subr_addr.
        by rewrite mulNr opprK mul1r opprD addrA.
      - by apply/mulr_gt0 => //; apply/expr_gt0.
      move => [->> [->> [->> ->>]]].
      move: {Hncond_start1 Hncond_start2 Hinv_start}.
      split.
      - move: Hinv_len_post.
        rewrite lezNgt expr_gt0 //= -!exprSr; first by move/mem_range: Hk_range.
        * by apply/subr_ge0/ltzW; move/mem_range: Hk_range.
        rewrite addrAC /= divz_pow //=.
        * rewrite subr_ge0 -ler_subr_addr opprK -ler_subl_addl /=; move/mem_range: Hk_range => [-> ? /=].
          by apply/ltzW/ltzE/ltzW/ltr_subr_addr.
        rewrite mulNr opprK mul1r opprD /= /(\o) /bitrev_8_update_r_j.
        pose Hinv1:= (FOLDR_RHL_FOR_NAT_DIV_GE_MUL_LE.inv _ _ _ _ _ _ _ _ _ _ _ _ _).
        pose Hinv2:= (FOLDR_RHL_FOR_NAT_DIV_GE_MUL_LE.inv _ _ _ _ _ _ _ _ _ _ _ _ _).
        rewrite -(eqT Hinv1) -(eqT Hinv2) /Hinv1 /Hinv2 => <- {Hinv1 Hinv2}.
        rewrite {6 8}/update_r_j_start /update_r_j_start_partial.
        rewrite bitrev_pow2; first by move: Hk_range; apply/mem_range_incl.
        rewrite -exprSr; first by apply/subr_ge0/ltzW; move/mem_range: Hk_range.
        rewrite addrAC /= -exprSr; first by apply/subr_ge0/ltzW; move/mem_range: Hk_range.
        rewrite addrAC /= divz_pow //=.
        * rewrite subr_ge0 -ler_subr_addr opprK -ler_subl_addl /=.
          by move/mem_range: Hk_range => [-> ? /=]; apply/ltzW/ltzE/ltzW/ltr_subr_addr.
        rewrite opprD opprK /= foldr_comp map_rev -map_comp; congr => //.
        apply foldr_perm_in.
        * move => r ? ?; rewrite !mem_rev => /mapP [x [Hx_range ->>]] /mapP [y [Hy_range ->>]].
          apply update_r_j_comm.
          + by rewrite mem_range_subl /=; move: Hk_range; apply/mem_range_incl.
          + rewrite addrAC /= bitrev_range_dvdz ?opprD //.
            rewrite subr_ge0 -ler_subr_addr opprK -ler_subl_addl.
            by move/mem_range: Hk_range => [-> ? /=]; apply/ltzW/ltzE/ltzW/ltr_subr_addr.
          + rewrite opprD /= range_div_range /=; first by apply/expr_gt0.
            rewrite -exprD_nneg; first by move/mem_range: Hk_range.
            - by apply/subr_ge0/ltzW/ltzE/ltzW/ltr_subr_addr; move/mem_range: Hk_range.
            by rewrite addrA addrAC /= (bitrev_range 8).
          + rewrite addrAC /= bitrev_range_dvdz ?opprD //.
            rewrite subr_ge0 -ler_subr_addr opprK -ler_subl_addl.
            by move/mem_range: Hk_range => [-> ? /=]; apply/ltzW/ltzE/ltzW/ltr_subr_addr.
          rewrite opprD /= range_div_range /=; first by apply/expr_gt0.
          rewrite -exprD_nneg; first by move/mem_range: Hk_range.
          + by apply/subr_ge0/ltzW/ltzE/ltzW/ltr_subr_addr; move/mem_range: Hk_range.
          by rewrite addrA addrAC /= (bitrev_range 8).
        rewrite (perm_eq_trans _ _ _ _ (perm_eq_rev (map (transpose Int.( * ) (2 ^ (8 - k))) (range 0 (2 ^ k))))) perm_eq_sym.
        rewrite (perm_eq_trans _ _ _ _ (perm_eq_rev (map (bitrev 8 \o fun (n : int) => n) (range 0 (2 ^ k))))).
        rewrite perm_eq_sym (eq_map _ (bitrev 8)) //.
        rewrite (perm_eq_trans _ _ _ (bitrev_range_pow2_perm_eq k 8 _)).
        * by move/mem_range: Hk_range => [-> ? /=]; apply/ltzW/ltzE/ltzW/ltr_subr_addr.
        by apply/perm_eq_refl_eq/eq_map => x; rewrite mulrC.
      apply/iffE => {Hinv_len_post}.
      rewrite mulrC -lez_divRL ?expr_gt0 // divz_pow //=.
      - by move/mem_range: Hk_range => [-> ? /=]; apply/ltzS.
      rewrite -{3}(IntID.expr1 2) divz_pow //=.
      - by apply/gtr_eqF/expr_gt0.
      - by rewrite vp_pow //; [apply/subr_ge0/ltzW|apply/ler_subr_addl/ltzE]; move/mem_range: Hk_range.
      rewrite vp_pow //; first by apply/subr_ge0/ltzW; move/mem_range: Hk_range.
      by rewrite divzz addrAC /= /b2i gtr_eqF //=; apply/expr_gt0.
    skip => |>.
    rewrite FOLDR_RHL_FOR_NAT_DIV_GE_MUL_LE.inv_in //=.
    move => len1 r1 len2 r2 Hncond_len1 Hncond_len2 Hinv_len.
    move: (FOLDR_RHL_FOR_NAT_DIV_GE_MUL_LE.inv_outP _ _ _ _ _ _ _ _ _ _ _ 64 _ _
            _ _ _ Hncond_len1 Hinv_len) => //=.
    move => |>.
    rewrite /bitrev_8_update_r_j_start foldr_comp; congr; rewrite map_rev; congr.
    rewrite -map_comp -eq_in_map => k Hk_range; rewrite /(\o) /=.
    rewrite bitrev_pow2 /=; first by move: Hk_range; apply range_incl.
    by rewrite divz_pow //=; move/mem_range: Hk_range => [-> /=]; apply/ltzW.
  qed.

  op zetas_spec (zs : Fq Array128.t) =
    forall i ,
      0 <= i < 128 =>
      zs.[i] = R * exp zeta1 (bitrev 8 (i * 2)).

  lemma eq_NTT3_NTT4 p zs :
    zetas_spec zs =>
    equiv [NTT3.ntt ~ NTT4.ntt:
      arg{1} = (p, zs) /\ arg{2} = (p) ==> ={res}].
  admitted. (* Broken 
  proof.
    move => Hzs.
    proc; sp.
    while (
      FOR_NAT_DIV_GE.inv 2 2 128 len{1} /\
      ={len, r} /\
      zetas{1} = zs).
    + sp; wp => /=.
      while (
        2 <= len{1} /\
        FOR_NAT_DIV_GE.inv 2 2 128 len{1} /\
        FOR_INT_ADD_LT.inv (len{1} * 2) 256 0 start{1} /\
        ={len, r, start} /\
        zetas{1} = zs).
      - sp; wp => /=.
        while (
          2 <= len{1} /\
          FOR_NAT_DIV_GE.inv 2 2 128 len{1} /\
          start{1} < 256 /\
          FOR_INT_ADD_LT.inv (len{1} * 2) 256 0 start{1} /\
          ={len, r, start, zeta_, j} /\
          zetas{1} = zs).
        * by sp; skip.
        skip => |> &hr2.
        (*TODO: why the mixup?*)
        move => Hcond_len Hinv_len; move: (FOR_NAT_DIV_GE.inv_loopP _ _ _ _ _ Hcond_len Hinv_len) => //= [k [Hk_range ->>]].
        move => {Hcond_len Hinv_len}.
        do 3!(rewrite divz_pow //=; first by smt(mem_range)).
        rewrite -exprSr; first by smt(mem_range).
        rewrite opprD /= (addzC _ k).
        move => Hinv_start Hcond_start; move: (FOR_INT_ADD_LT.inv_loopP _ _ _ _ _ Hcond_start Hinv_start) => //=; first by apply/expr_gt0.
        move => [start [Hstart_range ->>]].
        do 2!(rewrite -divzpMr; first by apply dvdz_exp2l; smt(mem_range)).
        do 2!(rewrite -exprD_subz //; [by smt(mem_range)|rewrite addrAC /=]).
        rewrite opprD /= addrAC !addrA /= -addrA /=.
        rewrite (FOR_INT_ADD_LT.inv_loop_post _ _ _ _ _ Hcond_start Hinv_start) ?expr_gt0 //=.
        rewrite Hzs; first split; first by admit; last by admit.
        move: Hstart_range.
        rewrite divz_pow //=; first by smt(mem_range).
        rewrite opprD mulNr /= => Hstart_range.
        split => [|_]; first by apply/addz_ge0; [apply/expr_ge0|move: Hstart_range => /mem_range []].
        apply/(ltr_le_trans (2 ^ (k + 1))).
        * rewrite exprD_nneg //=; first by move: Hk_range => /mem_range [].
          by rewrite -addr_double ler_lt_add //; move: Hstart_range => /mem_range.
        move: (ler_weexpn2l 2 _ (k + 1) 7) => //= -> //; move: Hk_range => /mem_range [? ?].
        by rewrite -ltzE; split => //; apply addr_ge0.
      skip => |> &hr2.
      move => Hinv_len Hcond_len; rewrite (FOR_NAT_DIV_GE.inv_loop_post _ _ _ _ _ Hcond_len Hinv_len) //=.
      by rewrite FOR_INT_ADD_LT.inv_in /=; apply/mulr_gt0 => //; apply/(ltr_le_trans 2).
    skip => |>.
    by rewrite FOR_NAT_DIV_GE.inv_in.
  qed. *)

  equiv eq_NTT2_NTT3: NTT2.ntt ~ NTT3.ntt:
    ={arg} ==> ={res}.
  proof.
    proc; sp.
    while ((0 <= len{1}) /\ ={zetasctr, len, r, zetas}).
    + sp; wp => /=.
      while ((0 <= len{1}) /\ ={zetasctr, len, r, zetas, start}).
      - sp; wp => /=.
        while (   (0 <= len{1})
               /\ ={zetasctr, len, r, zetas, start, zeta_}
               /\ (FOR_INT_ADD_LT.inv 1 len{2} 0 j{2})
               /\ (j{1} = j{2} + start{2})).
        * sp; skip => |> &hr2 j r le0len.
          move => Hinv_j _ Hcond_j.
          rewrite (FOR_INT_ADD_LT.inv_loop_post _ _ _ _ _ Hcond_j Hinv_j) //=.
          move: (FOR_INT_ADD_LT.inv_loopP _ _ _ _ _ Hcond_j Hinv_j) => //= [bsj [Hbsj_range ->>]].
          by rewrite !(IntID.addrAC _ start{hr2}) /= (IntID.addrC start{hr2}) ltr_add2r.
        skip => |> &hr2 le0len ltstart256.
        by rewrite ltr_addl !FOR_INT_ADD_LT.inv_in //=.
      by skip => /> &hr2 le0len _ _ _ _; apply/divz_ge0.
    by skip => />.
  qed. 

  equiv eq_NTT1_NTT2: NTT1.ntt ~ NTT2.ntt:
    ={arg} ==> ={res}.
  admitted. (* broken
  proof.
    proc; sp.
    while
      ( (exists k ,
          0 <= k < 8 /\
          len{1} = 2 ^ k) /\
        ={zetasctr, len, r, zetas} /\
        (zetasctr{1} + 1 = 128 %/ len{1})).
    + sp; wp => /=.
      while
        ( (exists k ,
            0 <= k < 8 /\
            len{1} = 2 ^ k) /\
          (FOR_INT_ADD_LT.inv (len{1} * 2) 256 0 start{1}) /\
          ={zetasctr, len, r, zetas, start} /\
          (zetasctr{1} + 1 = 128 %/ len{1} + start{1} %/ (len{1} * 2))).
      - sp; wp => /=.
        while
        ( (exists k ,
            0 <= k < 8 /\
            len{1} = 2 ^ k) /\
          (FOR_INT_ADD_LT.inv (len{1} * 2) 256 0 start{1}) /\
          ={zetasctr, len, r, zetas, start, zeta_, j} /\
          (zetasctr{1} = 128 %/ len{1} + start{1} %/ (len{1} * 2))).
        * by sp; skip => |>.
        skip => |> &hr2 zetasctr k le0k ltk8 Hinv Hzetasctr Hcond.
        rewrite Hzetasctr /= => _ _ _.
        rewrite FOR_INT_ADD_LT.inv_loop_post //=; first by apply mulr_gt0 => //; apply expr_gt0.
        rewrite divzDr ?dvdzz // divzz addzA -Hzetasctr /b2i.
        have -> //=: 2 ^ k * 2 <> 0.
        by apply gtr_eqF; apply mulr_gt0 => //; apply expr_gt0.
      skip => |> &hr2 k le0k ltk8 Hzetasctr le22powk; do!split.
      - by rewrite FOR_INT_ADD_LT.inv_in //=; apply mulr_gt0 => //; apply expr_gt0.
      move => start zetasctr Hncond _ Hinv ->; split.
      - exists (k-1); do!split => //=.
        * by apply ler_subr_addr; apply ltzE; move: le0k => /le0r [->>|].
        * by move: ltk8 => /ltzW lek8 _; apply ltzE; rewrite -addzA.
        by apply Montgomery.pow_div1; move: le0k => /le0r [->>|].
      rewrite (FOR_INT_ADD_LT.inv_outP _ _ _ _ _ Hncond Hinv) //=; first by apply/mulr_gt0 => //; apply expr_gt0.
      rewrite /out /= mulzK; first by apply gtr_eqF; apply mulr_gt0 => //; apply expr_gt0.
      rewrite (mulzC (2 ^ k) 2) Montgomery.div_mul //= dvdNdiv; first by apply/gtr_eqF/expr_gt0.
      - by move : (dvdz_exp2l 2 k 7) => /= Hdiv; apply Hdiv; rewrite le0k -ltzS.
      rewrite opprK -(divzMpr 2 128 (_ %/ _)) //= divzK.
      - move: (ilog_mono 2 _ _ _ _ le22powk); rewrite //= ilog_powK //= => le1k.
        by move: (dvdz_exp2l 2 1 k); rewrite le1k.
      by rewrite -divzDl //=; move: (dvdz_exp2l 2 k 7); rewrite /= le0k -ltzS /= ltk8.
    by skip => />; exists 7; split.
  qed. *)

  equiv eq_NTT_NTT1: NTT.ntt ~ NTT1.ntt:
    ={arg} ==> ={res}.
  proof.
    proc; sp.
    while ((0 <= len{1}) /\ ={zetasctr, len, r, zetas}).
    + sp; wp => /=.
      while ((0 <= len{1}) /\ ={zetasctr, len, r, zetas, start}).
      - sp; wp => /=.
        while (   (0 <= len{1})
               /\ ={zetasctr, len, r, zetas, start, zeta_, j}
               /\ (FOR_INT_ADD_LT.inv 1 (start{1} + len{1}) start{1} j{1})).
        * sp; skip => |> &hr2 j le0len.
          (*TODO: match order between pRHL, pHL and HL.*)
          by move => Hinv_j Hcond_j; move: (FOR_INT_ADD_LT.inv_loop_post _ _ _ _ _ Hcond_j Hinv_j).
        skip => |> &hr2 le0len ltstart256; split.
        + by apply FOR_INT_ADD_LT.inv_in.
        move => j _.
        move => Hncond Hinv.
        rewrite (FOR_INT_ADD_LT.inv_outP _ _ _ _ _ Hncond Hinv) //=.
        by smt(mem_range).
      by skip => /> &hr2 le0len _ _ _ _; apply/divz_ge0.
    by skip => />.
  qed.
 





  op zetas_inv_spec = zetas_spec.

  lemma eq_inv_NTT3_NTT4 p zs :
    zetas_inv_spec zs =>
    equiv [NTT3.invntt ~ NTT4.invntt:
      arg{1} = (p, zs) /\ arg{2} = (p) ==> ={res}].
  admitted. (* broken
  proof.
    move => Hzs.
    proc; sp.
    while (={r, j} /\ zetas_inv{1} = zs).
    + wp; skip => &hr1 &hr2 /> _; rewrite Hzs //=.
      do 8!(rewrite bitrev_cons ?dvdzE /b2i //=); rewrite bitrev0 /=.
    wp.
    while (
      FOR_NAT_DIV_GE.inv 2 2 128 len{1} /\
      ={len, r} /\
      zetas{1} = zs).
    + sp; wp => /=.
      while (
        2 <= len{1} /\
        FOR_NAT_DIV_GE.inv 2 2 128 len{1} /\
        FOR_INT_ADD_LT.inv (len{1} * 2) 256 0 start{1} /\
        ={len, r, start} /\
        zetas{1} = zs).
      - sp; wp => /=.
        while (
          2 <= len{1} /\
          FOR_NAT_DIV_GE.inv 2 2 128 len{1} /\
          start{1} < 256 /\
          FOR_INT_ADD_LT.inv (len{1} * 2) 256 0 start{1} /\
          ={len, r, start, zeta_, j} /\
          zetas{1} = zs).
        * by sp; skip.
        skip => |> &hr2.
        (*TODO: why the mixup?*)
        move => Hcond_len Hinv_len; move: (FOR_NAT_DIV_GE.inv_loopP _ _ _ _ _ Hcond_len Hinv_len) => //= [k [Hk_range ->>]].
        move => {Hcond_len Hinv_len}.
        do 3!(rewrite divz_pow //=; first by smt(mem_range)).
        rewrite -exprSr; first by smt(mem_range).
        rewrite opprD /= (addzC _ k).
        move => Hinv_start Hcond_start; move: (FOR_INT_ADD_LT.inv_loopP _ _ _ _ _ Hcond_start Hinv_start) => //=; first by apply/expr_gt0.
        move => [start [Hstart_range ->>]].
        do 2!(rewrite -divzpMr; first by apply dvdz_exp2l; smt(mem_range)).
        do 2!(rewrite -exprD_subz //; [by smt(mem_range)|rewrite addrAC /=]).
        rewrite opprD /= addrAC !addrA /= -addrA /=.
        rewrite (FOR_INT_ADD_LT.inv_loop_post _ _ _ _ _ Hcond_start Hinv_start) ?expr_gt0 //=.
        rewrite Hzs; last by rewrite mulzDl -exprSr; first by smt(mem_range).
        move: Hstart_range.
        rewrite divz_pow //=; first by smt(mem_range).
        rewrite opprD mulNr /= => Hstart_range.
        split => [|_]; first by apply/addz_ge0; [apply/expr_ge0|move: Hstart_range => /mem_range []].
        apply/(ltr_le_trans (2 ^ (k + 1))).
        * rewrite exprD_nneg //=; first by move: Hk_range => /mem_range [].
          by rewrite -addr_double ler_lt_add //; move: Hstart_range => /mem_range.
        move: (ler_weexpn2l 2 _ (k + 1) 7) => //= -> //; move: Hk_range => /mem_range [? ?].
        by rewrite -ltzE; split => //; apply addr_ge0.
      skip => |> &hr2.
      move => Hinv_len Hcond_len; rewrite (FOR_NAT_DIV_GE.inv_loop_post _ _ _ _ _ Hcond_len Hinv_len) //=.
      by rewrite FOR_INT_ADD_LT.inv_in /=; apply/mulr_gt0 => //; apply/(ltr_le_trans 2).
    skip => |>.
    by rewrite FOR_NAT_DIV_GE.inv_in.
  qed. *)

  equiv eq_inv_NTT2_NTT3: NTT2.invntt ~ NTT3.invntt:
    ={arg} ==> ={res}.
  proof.
    proc; sp.
    while (={r, zetas_inv, j}).
    + by wp; skip => &hr1 &hr2 />.
    wp.
    while ((0 <= len{1}) /\ ={zetasctr, len, r, zetas_inv}).
    + sp; wp => /=.
      while ((0 <= len{1}) /\ ={zetasctr, len, r, zetas_inv, start}).
      - sp; wp => /=.
        while (   (0 <= len{1})
               /\ ={zetasctr, len, r, zetas_inv, start, zeta_}
               /\ (FOR_INT_ADD_LT.inv 1 len{2} 0 j{2})
               /\ (j{1} = j{2} + start{2})).
        * sp; skip => |> &hr2 j r.
          move => Hinv_j _ Hcond_j.
          rewrite (FOR_INT_ADD_LT.inv_loop_post _ _ _ _ _ Hcond_j Hinv_j) //=.
          move: (FOR_INT_ADD_LT.inv_loopP _ _ _ _ _ Hcond_j Hinv_j) => //= [bsj [Hbsj_range ->>]].
          by rewrite !(IntID.addrAC _ start{hr2}) /= (IntID.addrC start{hr2}) ltr_add2r.
        skip => |> &hr2 le0len ltstart256.
        by rewrite ltr_addl !FOR_INT_ADD_LT.inv_in //=.
      by skip => /> &hr2 le0len _ _ _ _; apply/mulr_ge0.
    by skip => />.
  qed.

  equiv eq_inv_NTT1_NTT2: NTT1.invntt ~ NTT2.invntt:
    ={arg} ==> ={res}.
  admitted. (* Broken 
  proof.
    proc; sp.
    while (={r, zetas_inv, j}).
    + by wp; skip => &hr1 &hr2 />.
    wp.
    while
      ( (exists k ,
          1 <= k < 9 /\
          len{1} = 2 ^ k) /\
        ={len, r, zetas_inv} /\
        (zetasctr{1} =        128 - 256 %/ len{1}) /\
        (zetasctr{2} = max 0 (128 - 256 %/ len{1} - 1))).
    + sp; wp => /=.
      while
        ( (exists k ,
            1 <= k < 9 /\
            len{1} = 2 ^ k) /\
          (FOR_INT_ADD_LT.inv (len{1} * 2) 256 0 start{1}) /\
          ={len, r, zetas_inv, start} /\
          (zetasctr{1} =        128 - 256 %/ len{1} + start{1} %/ (len{1} * 2)) /\
          (zetasctr{2} = max 0 (128 - 256 %/ len{1} + start{1} %/ (len{1} * 2) - 1))).
      - sp; wp => /=.
        while
        ( (exists k ,
            1 <= k < 9 /\
            len{1} = 2 ^ k) /\
          (FOR_INT_ADD_LT.inv (len{1} * 2) 256 0 start{1}) /\
          ={len, r, zetas_inv, start, zeta_, j} /\
          (zetasctr{1} = 128 - 256 %/ len{1} + start{1} %/ (len{1} * 2) + 1) /\
          (zetasctr{2} = 128 - 256 %/ len{1} + start{1} %/ (len{1} * 2))).
        * by sp; skip => |>.
        skip => |> &hr2 k le1k ltk9 Hinv Hcond _ _ _.
        rewrite FOR_INT_ADD_LT.inv_loop_post //=; first by apply mulr_gt0 => //; apply expr_gt0.
        rewrite divzDr ?dvdzz // divzz addzA /b2i.
        have -> //=: 2 ^ k * 2 <> 0 by apply gtr_eqF; apply mulr_gt0 => //; apply expr_gt0.
        move: (FOR_INT_ADD_LT.inv_loopP _ _ _ _ _ Hcond Hinv); first by right; apply mulr_gt0 => //; apply expr_gt0.
        move => /= [s [Hsrange ->>]]; rewrite mulzK; first by apply gtr_eqF; apply mulr_gt0 => //; apply expr_gt0.
        rewrite ler_maxr // addr_ge0; last by move/mem_range: Hsrange.
        rewrite subr_ge0 divz_pow //=; first by rewrite -(ltzS _ 8) /= ltk9 /= (lez_trans 1).
        move: (ler_weexpn2l 2 _ (8 - k) 7) => //= -> //.
        by rewrite subr_ge0 -ltzS /= ltk9 /= ler_subl_addr -ler_subl_addl.
      skip => |> k le1k ltk9 le22powk; do!split.
      - by rewrite FOR_INT_ADD_LT.inv_in //=; apply mulr_gt0 => //; apply expr_gt0.
      move => start Hncond _ Hinv; split.
      - exists (k+1); do!split => //=.
        * smt().
        * by move => _; rewrite ltzE /= -ler_subr_addr /=; apply (ler_weexpn2r 2); rewrite // (ler_trans 1).
        by rewrite exprSr // (ler_trans 1).
      rewrite (FOR_INT_ADD_LT.inv_outP _ _ _ _ _ Hncond Hinv) //=; first by apply/mulr_gt0 => //; apply expr_gt0.
      rewrite /out /= mulzK; first by apply gtr_eqF; apply mulr_gt0 => //; apply expr_gt0.
      rewrite (mulzC (2 ^ k) 2) Montgomery.div_mul //= dvdNdiv; first by apply/gtr_eqF/expr_gt0.
      - move : (dvdz_exp2l 2 k 7) => /= Hdiv; apply Hdiv; rewrite (ler_trans 1) //=.
        by apply (ler_weexpn2r 2); rewrite // (ler_trans 1).
      rewrite -exprS; first by smt().
      rewrite divz_pow //=; first by smt().
      rewrite divz_pow //=; first by rewrite (ler_trans 1) //=; apply (ler_weexpn2r 2); rewrite // (ler_trans 1).
      rewrite divz_pow //=.
      - by rewrite (ler_trans 2) // -?ler_subl_addr //= -ler_subr_addr /=; apply (ler_weexpn2r 2); rewrite // (ler_trans 1).
      move: (IntID.exprS 2 (7 - k)); rewrite opprD addrA (addzAC 8) /= !(addzAC _ _ (-1)) /= -!addrA => ->.
      - by rewrite subr_ge0; apply (ler_weexpn2r 2); rewrite // (ler_trans 1).
      by rewrite -mulNr -mulrD1l /= mulNr.
    by skip => />; exists 1; split.
  qed. *)

  equiv eq_inv_NTT_NTT1: NTT.invntt ~ NTT1.invntt:
    ={arg} ==> ={res}.
  proof.
    proc; sp.
    while (={r, zetas_inv, j}).
    + by wp; skip => &hr1 &hr2 />.
    wp.
    while ((0 <= len{1}) /\ ={zetasctr, len, r, zetas_inv}).
    + sp; wp => /=.
      while ((0 <= len{1}) /\ ={zetasctr, len, r, zetas_inv, start}).
      - sp; wp => /=.
        while (   (0 <= len{1})
               /\ ={zetasctr, len, r, zetas_inv, start, zeta_, j}
               /\ (FOR_INT_ADD_LT.inv 1 (start{1} + len{1}) start{1} j{1})).
        * sp; skip => |> &hr2 j le0len.
          by move => Hinv_j Hcond_j; move: (FOR_INT_ADD_LT.inv_loop_post _ _ _ _ _ Hcond_j Hinv_j).
        skip => |> &hr2 le0len ltstart256; split.
        + by apply FOR_INT_ADD_LT.inv_in.
        move => j _.
        move => Hncond Hinv.
        rewrite (FOR_INT_ADD_LT.inv_outP _ _ _ _ _ Hncond Hinv) //=.
        by smt(mem_range).
      by skip => /> &hr2 le0len _ _ _ _; apply/mulr_ge0.
    by skip => />.
  qed.

end NTTequiv.

