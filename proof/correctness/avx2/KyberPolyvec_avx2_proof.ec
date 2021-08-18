require import AllCore List Int IntDiv CoreMap Real Number.
from Jasmin require import JModel.
require import Fq Array16 Array32 Array128 Array256 Array400 Array768.
require import W16extra WArray32 WArray256 WArray512 WArray800 WArray1536 WArray168 WArray800.
require import Ops.
require import List_hakyber.
require import KyberCPA_avx2.
require import KyberPolyvec_avx2_prevec.
require import KyberPoly_avx2_proof.
require import Fq_avx2.
require import KyberPolyVec.

theory KyberPolyvecAVX.

import Fq.
import SignedReductions.
import Kyber_.
import ZModField.
import KyberPolyAVX.
import KyberPolyVec.

lemma polvec_add_corr_h _a _b ab bb:
      hoare[Mavx2_prevec.polyvec_add2:
           (0 <= ab <= 6 /\ 0 <= bb <= 3) /\
           _a = lift_array768 r /\
           _b = lift_array768 b /\
           signed_bound768_cxq r 0 768 ab /\
           signed_bound768_cxq b 0 768 bb
           ==>
           signed_bound768_cxq res 0 768 (ab + bb) /\
           forall k, 0 <= k < 768 =>
             inzmod (to_sint res.[k]) = _a.[k] + _b.[k]].
proof.
  proc.
  wp.
  ecall (KyberPolyAVX.poly_add_corr (lift_array256 (Array256.init (fun i => r.[(2 * 256) + i]))) (lift_array256 (Array256.init (fun i => b.[(2 * 256) + i]))) ab bb).
  wp.
  ecall (KyberPolyAVX.poly_add_corr (lift_array256 (Array256.init (fun i => r.[256 + i]))) (lift_array256 (Array256.init (fun i => b.[256 + i]))) ab bb).
  wp.
  ecall (KyberPolyAVX.poly_add_corr (lift_array256 (Array256.init (fun i => r.[0 + i]))) (lift_array256 (Array256.init (fun i => b.[0 + i]))) ab bb).
  wp. skip.
  move => &hr [[a_i b_i] [_a_def] [_b_def] [sgnd_bnd_rp] sgnd_bnd_bp].
  rewrite a_i b_i => />.
  split.
  smt(@Array768 @Array256).
  move => sgnd_bnd_rp_1 sgnd_bnd_bp_1 result_1 sgnd_bnd_res_1 res_1_def.
  split.
  smt(@Array256 @Array768).
  move => sgnd_bnd_rp_2 sgnd_bnd_bp_2 result_2 sgnd_bnd_res_2 res_2_def.
  split.
  smt(@Array256 @Array768).
  move => sgnd_bnd_rp_3 sgnd_bnd_bp_3 result_3 sgnd_bnd_res_3 res_3_def.
  split.
  rewrite /signed_bound768_cxq.
  rewrite /signed_bound_cxq /b16 in sgnd_bnd_res_1.
  rewrite /signed_bound_cxq /b16 in sgnd_bnd_res_2.
  rewrite /signed_bound_cxq /b16 in sgnd_bnd_res_3.
  move => k k_i.
  do rewrite initiE //=.
  move : (sgnd_bnd_res_1 k) (sgnd_bnd_res_2 (k - 256)) (sgnd_bnd_res_3 (k - 512)).
  smt(@Array768 @Array256 @Int).
  move => k k_lb k_ub.
  do rewrite initiE //=.
  case (0 <= k < 256) => k_si.
  move : (res_1_def k k_si).
  move : _a_def _b_def.
  smt(@Array256 @Array768 @KyberPolyAVX @Int).
  case (k < 512) => k_ssi.
  move : (res_2_def (k - 256)).
  rewrite (_: (0 <= k - 256 && k - 256 < 256) = true). move : k_si k_ub k_ssi => /#.
  simplify.
  move : _a_def _b_def.
  smt(@Array256 @Array768 @KyberPolyAVX @Int).
  move : (res_3_def (k - 512)).
  rewrite (_: (0 <= k - 512 && k - 512 < 256) = true). move : k_si k_ub k_ssi => /#.
  simplify.
  move : _a_def _b_def.
  rewrite -lezNgt in k_ssi.
  rewrite k_ub k_ssi //=.
  rewrite /lift_array256.
  do rewrite mapiE 1:/#.
  do rewrite initiE 1:/#.
  smt(@Array256 @Array768 @KyberPolyAVX @Int).
qed.


lemma polyvec_csubq_corr ap :
  hoare[Mavx2_prevec.polyvec_csubq:
       ap = lift_array768 r /\
       pos_bound768_cxq r 0 768 2
       ==>
       ap = lift_array768 res /\
       pos_bound768_cxq res 0 768 1].
proof.
  proc; sp.
  wp.
  ecall (KyberPolyAVX.poly_csubq_corr_h (lift_array256 (Array256.init (fun (i : int) => r.[2 * 256 + i])))).
  wp.
  ecall (KyberPolyAVX.poly_csubq_corr_h (lift_array256 (Array256.init (fun (i : int) => r.[256 + i])))).
  wp.
  ecall (KyberPolyAVX.poly_csubq_corr_h (lift_array256 (Array256.init (fun (i : int) => r.[i])))).
   wp. skip.
   move => &hr [ap_def pos_bound_r]; split.
   split; trivial; smt(@Array256).
   move => [r_eq_r_1 pos_bound_r_1 res1 [r_eq_res_1 pos_bound_res_1] res_1_def]; split.
   split; trivial; smt(@Array768 @Array256).
   move => [r_eq_r_2 pos_bound_r_2 res2 [r_eq_res_2 pos_bound_res_2] res_2_def]; split.
   split; trivial; smt(@Array768 @Array256).
   move => [r_eq_r_3 pos_bound_r_3 res3 [r_eq_res_3 pos_bound_res_3] res_3_def]; split.
   rewrite /res_3_def /res_2_def /res_1_def /=.
   rewrite ap_def.
   rewrite lift_array768P; move => k k_i.
   do rewrite initiE 1:/# //=.
   do rewrite fun_if.
   rewrite lift_array256P //= in r_eq_res_3.
   rewrite lift_array256P //= in r_eq_res_2.
   rewrite lift_array256P //= in r_eq_res_1.
   case (512 <= k < 768) => k_si.
   rewrite -(r_eq_res_3 (k - 512)) 1:/#.
   do rewrite initiE 1:/# //=.
   rewrite (_: (256 <= k && k < 512) = false) 1:/# //=.
   rewrite (_: (0 <= k && k < 256) = false) 1:/# //=.
   case (256 <= k < 512) => k_ssi.
   rewrite -(r_eq_res_2 (k -  256)) 1:/#.
   do rewrite initiE 1:/# //=.
   rewrite (_: (0 <= k && k < 256) = false) 1:/# //=.
   rewrite -(r_eq_res_1 k) 1:/#.
   do rewrite initiE 1:/# //=.
   rewrite /res_3_def /res_2_def /res_1_def.
   rewrite /pos_bound768_cxq => k k_i.
   do rewrite initiE //=.
   rewrite /pos_bound256_cxq /bpos16 //=in pos_bound_res_3.
   rewrite /pos_bound256_cxq /bpos16 //=in pos_bound_res_2.
   rewrite /pos_bound256_cxq /bpos16 //=in pos_bound_res_1.
   move : (pos_bound_res_3 (k - 512))  (pos_bound_res_2 (k - 256))  (pos_bound_res_1 k).
   smt(@Array256 @Array768).
qed.


lemma polyvec_reduce_corr _a:
  hoare[Mavx2_prevec.polyvec_reduce:
       _a  = lift_array768 r ==>
       _a  = lift_array768 res /\
       forall k, 0 <= k < 768 => bpos16 res.[k] (2*Kyber_.q)].
proof.
  proc; sp.
  wp.
  ecall (KyberPolyAVX.poly_reduce_corr_h (lift_array256 (Array256.init (fun (i : int) => r.[2 * 256 + i])))).
  wp.
  ecall (KyberPolyAVX.poly_reduce_corr_h (lift_array256 (Array256.init (fun (i : int) => r.[256 + i])))).
  wp.
  ecall (KyberPolyAVX.poly_reduce_corr_h (lift_array256 (Array256.init (fun (i : int) => r.[i])))).
  wp. skip.
  move => &hr _a_def.
  split; first by trivial.
  move => r_eq_r_1 res1 [r_eq_res1 res1_bound] res1_def res2 [r_eq_res2 res2_bound] res2_def res3 [r_eq_res3 res3_bound] res3_def.
  split.
  rewrite /res3_def /res2_def /res1_def /=.
  rewrite _a_def.
  rewrite lift_array768P; move => k k_i.
  do rewrite initiE 1:/# //=.
  do rewrite fun_if.
  rewrite lift_array256P //= in r_eq_res3.
  rewrite lift_array256P //= in r_eq_res2.
  rewrite lift_array256P //= in r_eq_res1.  
   case (512 <= k < 768) => k_si.
   rewrite -(r_eq_res3 (k - 512)) 1:/#.
   do rewrite initiE 1:/# //=.
   rewrite (_: (256 <= k && k < 512) = false) 1:/# //=.
   rewrite (_: (0 <= k && k < 256) = false) 1:/# //=.
   case (256 <= k < 512) => k_ssi.
   rewrite -(r_eq_res2 (k -  256)) 1:/#.
   do rewrite initiE 1:/# //=.
   rewrite (_: (0 <= k && k < 256) = false) 1:/# //=.
   rewrite -(r_eq_res1 k) 1:/#.
   do rewrite initiE 1:/# //=.
   rewrite /res3_def /res2_def /res1_def.
   move => k k_i.
   do rewrite initiE //=.
   rewrite /bpos16 //=in res3_bound.
   rewrite /bpos16 //=in res2_bound.
   rewrite /bpos16 //=in res1_bound.
   move : (res3_bound (k - 512))  (res2_bound (k - 256))  (res1_bound k).
   smt(@Array256 @Array768).
qed.

end KyberPolyvecAVX.
