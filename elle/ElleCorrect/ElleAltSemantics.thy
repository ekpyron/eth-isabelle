theory ElleAltSemantics
  imports Main "Valid4" "../../EvmFacts" "../../example/termination/ProgramList"
begin

(*
Alternate, inductive Elle semantics
Idea is that jumps nondeterministically go to _all_ applicable labels
*)

(* first we need a way to get the next childpath *)
(* this function assumes that this one is a genuine
childpath, it tries to find the next one.
*)


(* is this actually the behavior we want? *)
(* yes, if we implement "falling through" Seq nodes in the inductive
semantics *)
fun cp_next' :: "('a, 'b, 'c, 'd, 'e, 'f, 'g) ll \<Rightarrow> childpath \<Rightarrow> childpath option" where
 "cp_next' t p =
   (case (rev p) of
    [] \<Rightarrow> None
    | final#rrest \<Rightarrow> 
      (case (ll_get_node t (rev ((final+1)#rrest))) of
        Some _ \<Rightarrow> Some (rev ((final + 1)#rrest))
        | None \<Rightarrow> cp_next' t (rev rrest) 
))
 "

(*
(* prevent simplification until we want it *)
definition cp_next :: "('a, 'b, 'c, 'd, 'e, 'f, 'g) ll \<Rightarrow> childpath \<Rightarrow> childpath option" where
"cp_next = cp_next'"
*)

(* also have cp_next_list here? *)
(* this seems not quite right... *)
(* there are a lot of cases here, we can probably cut down *)
fun cp_next :: "('a, 'b, 'c, 'd, 'e, 'f, 'g) ll \<Rightarrow> childpath \<Rightarrow> childpath option"
and cp_next_list :: "('a, 'b, 'c, 'd, 'e, 'f, 'g) ll list \<Rightarrow> childpath \<Rightarrow> childpath option" 
where
"cp_next (_, LSeq _ l) (cp) = cp_next_list l cp"
| "cp_next _ _ = None"

| "cp_next_list [] _ = None"
| "cp_next_list _ [] = None" (* corresponds to running off the end*)
(* idea: maintain a lookahead of 1. this is why we talk about both cases *)
(* do we need to be tacking on a 0 *)
| "cp_next_list ([h]) (0#cpt) =
    (case cp_next h cpt of None \<Rightarrow> None 
                         | Some res \<Rightarrow> Some (0#res))"
| "cp_next_list ([h]) ((Suc n)#cpt) = None"
| "cp_next_list (h1#h2#t) (0#cpt) =
    (case cp_next h1 cpt of
      Some cp' \<Rightarrow> Some (0#cp')
     | None \<Rightarrow> Some [1])"
| "cp_next_list (h#h2#t) (Suc n # cpt) =
    (case cp_next_list (h2#t) (n # cpt) of
      Some (n'#cp') \<Rightarrow> Some (Suc n' # cp')
     | _ \<Rightarrow> None)
    "

(* this was an interesting experiment but probably not a useful primitive *)
inductive cp_nexti :: "('a, 'b, 'c, 'd, 'e, 'f, 'g) ll \<Rightarrow> childpath \<Rightarrow> childpath \<Rightarrow> bool" where
"\<And> t cpp q e ld n . ll_get_node t cpp = Some (q, LSeq e ld) \<Longrightarrow>
                   n + 1 < length ld \<Longrightarrow>
                   cp_nexti t (cpp@[n]) (cpp@[n+1])"
| "\<And> t cpp q e ld n cpp' . ll_get_node t cpp = Some (q, LSeq e ld) \<Longrightarrow>
            n + 1 = length ld \<Longrightarrow>
            cp_nexti t cpp cpp' \<Longrightarrow>
            cp_nexti t (cpp@[n]) cpp'"

(*
lemma ll_validl_split :
"! x1 x3 l2 . ((x1,x3), l1@l2) \<in> ll_validl_q \<longrightarrow>
  (? x2 . ((x1, x2), l1) \<in> ll_validl_q \<and>
         ((x2, x3), l2) \<in> ll_validl_q)"

proof(induction l1)
  case Nil
  then show ?case 
    apply(auto)
    apply(rule_tac x = x1 in exI)
    apply(auto simp add:ll_valid_q_ll_validl_q.intros)
    done
next
  case (Cons a l1)
  then show ?case 
    apply(auto)
    apply(drule_tac ll_validl_q.cases) apply(auto)
    apply(drule_tac x = n' in spec) apply(drule_tac x = n'' in spec)
    apply(drule_tac x = l2 in spec) apply(auto)
    apply(rule_tac x = x2 in exI) apply(auto simp add:ll_valid_q_ll_validl_q.intros)
    done
   
qed
*)


(*
inductive cp_lasti :: "('a, 'b, 'c, 'd, 'e, 'f, 'g) ll \<Rightarrow> childpath \<Rightarrow> bool" where
"
*)
            

value "cp_next ((0,0), LSeq () [((0,0), L () (Arith ADD)), 
                                ((0,0), L () (Arith ADD)),
                                ((0,0), L () (Arith ADD)),
                                ((0,0), LSeq () [
                                       ((0,0), L () (Arith ADD)),
                                       ((0,0), L () (Arith SUB))
                                  ]),
                                ((0,0), L () (Arith ADD))
                               ]) [3,1]"

value "cp_next ((0,0), LSeq () [((0,0), L () (Arith ADD)), 
                                ((0,0), L () (Arith ADD)),
                                ((0,0), L () (Arith ADD)),
                                ((0,0), LSeq () [
                                       ((0,0), L () (Arith ADD)),
                                       ((0,0), L () (Arith SUB))
                                  ]),
                                ((0,0), L () (Arith ADD))
                               ]) []"

(* TODO: state this sample lemma showing that we always return None
instead of a nil path *)
(* TODO we need tree induction here *)
lemma cp_next_nonnil' :
"(! cp cp' . cp_next (t :: ('a, 'b, 'c, 'd, 'e, 'f, 'g) ll) cp = Some cp' \<longrightarrow>
    (? cph' cpt' . cp' = cph' # cpt')) \<and>
(! cp cp' . cp_next_list (l :: ('a, 'b, 'c, 'd, 'e, 'f, 'g) ll list) cp = Some cp' \<longrightarrow>
    (? cph' cpt' . cp' = cph' # cpt'))
"
proof(induction rule:my_ll_induct)
  case (1 q e i)
  then show ?case by auto
next
  case (2 q e idx)
  then show ?case by auto
next
  case (3 q e idx n)
  then show ?case by auto
next
  case (4 q e idx n)
  then show ?case by auto
next
  case (5 q e l)
  then show ?case by auto
next
  case 6
  then show ?case by auto
next
  case (7 h l)
  then show ?case
    apply(auto)
    apply(case_tac cp, auto) apply(case_tac a, auto)
     apply(case_tac l, auto) apply(split option.split_asm) apply(auto)
     apply(split option.split_asm) apply(auto)
    apply(case_tac l, auto) apply(split option.split_asm) apply(auto)
    apply(case_tac x2, auto)
    done
qed

lemma cp_next_nonnil2 [rule_format]:
"
(! cp cp' . cp_next_list (l :: ('a, 'b, 'c, 'd, 'e, 'f, 'g) ll list) cp = Some cp' \<longrightarrow>
    (? cph' cpt' . cp' = cph' # cpt'))
"
  apply(insert cp_next_nonnil')
  apply(fastforce)
  done
(*
"(! t cp' . cp_next t cp = Some cp' \<longrightarrow>
  (? cph' cpt' . cp' = cph' # cpt'))"
proof(induction cp)
case Nil
  then show ?case
    apply(auto)
    apply(case_tac ba, auto) apply(case_tac x52, auto)
    done
next
  case (Cons a cp)
  then show ?case
    apply(auto)
    apply(case_tac ba, auto) apply(case_tac x52, auto)
    apply(
qed
*)
(* need more parameters *)
(* is initial childpath [] or [0]? *)
(* if it's a Seq, go to first child
if it's a jump, go to all targeted jump nodes
if it's any other node, interpret the node
and then go to cp_next *)
(*
have a constructor where if cp_next = None, then we are at the end of the tree
and so we just return (?)
we need to refactor this somehow, the naive approach is too verbose

one idea: what if we just have a separate function that checks if the
resultant cp_next is none?
*)

(* another way to simplify this: force us to enclose the entire thing in a Seq [...]
that doesn't have a label (e.g. only allows jumps in descendents) *)


definition bogus_prog :: program where
"bogus_prog = Evm.program.make (\<lambda> _ . Some (Pc JUMPDEST)) 0"


(* make this not use type parameters? *)
(* here is the old version that has type parameters *)
(* Key - here we need to make sure that we return InstructionToEnviroment
on the cases where we are stopping... 
use an empty and bogus program*)
(*
i think we can't maintain parametricity here...
also -  is returning the full ellest every time the right way to do this?
*)
(*
we need to avoid the PC overflowing spuriously, which is done by always resetting the
pc to 0
*)

(* we need a version of elle_alt_sem' that uses integer indices instead of childpaths to represent the program counter 
this seems less nice than using childpaths directly though.
after all what if we just used the EVM program counter directly (to describe where to point)?
then the semantics are less convincing.



*)

(*
TODO we need a "finalize" notion that runs STOP (essentially)
this will get run in every case where there is no next
child path
*)

(*
what is going on with check_resources for stop
*)

(* change this so that it is just running "stop" instead
 (otherwise it is going to do check_resources and other things *)
(* idea: if in a "continue" state, then run stop
   otherwise leave it alone *)
(*
fun elle_stop :: "instruction_result \<Rightarrow> constant_ctx \<Rightarrow> instruction_result" where
"elle_stop (InstructionContinue v) cc = stop v cc"
| "elle_stop ir _ = ir"
*)

(* TODO use next_state instead, or we may actually
just have to reconstruct it. *)
(*
fun elle_stop :: "instruction_result \<Rightarrow> constant_ctx \<Rightarrow> network \<Rightarrow> instruction_result" where
"elle_stop (InstructionContinue v) cc net = instruction_sem v cc (Misc STOP) net"
| "elle_stop ir _ _ = ir"
*)

(* based on next_state *)
fun elle_stop :: "instruction_result \<Rightarrow> constant_ctx \<Rightarrow> network \<Rightarrow> instruction_result" where
"elle_stop (InstructionContinue v) cc net = 
          (if check_resources v cc(vctx_stack   v) (Misc STOP) net then
          instruction_sem v cc (Misc STOP) net
        else
          InstructionToEnvironment (ContractFail
              ((case  inst_stack_numbers (Misc STOP) of
                 (consumed, produced) =>
                 (if (((int (List.length(vctx_stack   v)) + produced) - consumed) \<le>( 1024 :: int)) then [] else [TooLongStack])
                  @ (if meter_gas (Misc STOP) v cc net \<le>(vctx_gas   v) then [] else [OutOfGas])
               )
              ))
              v None)"
| "elle_stop ir _ _ = ir"

(*
        if check_resources v c(vctx_stack   v) i net then
          instruction_sem v c i net
        else
          InstructionToEnvironment (ContractFail
              ((case  inst_stack_numbers i of
                 (consumed, produced) =>
                 (if (((int (List.length(vctx_stack   v)) + produced) - consumed) \<le>( 1024 :: int)) then [] else [TooLongStack])
                  @ (if meter_gas i v c net \<le>(vctx_gas   v) then [] else [OutOfGas])
               )
              ))
              v None

*)

inductive elle_alt_sem :: "('a, 'b, 'c, 'd, 'e, 'f, 'g) ll \<Rightarrow> childpath \<Rightarrow>
            constant_ctx \<Rightarrow> network \<Rightarrow>
            instruction_result \<Rightarrow> instruction_result \<Rightarrow> bool" where
(* last node is an instruction *)
"\<And> t cp x e i cc net st st' st''.
    ll_get_node t cp = Some (x, L e i) \<Longrightarrow>
    cp_next t cp = None \<Longrightarrow>
    elle_instD' i (clearprog' cc) net (clearpc' st) = st' \<Longrightarrow>
    elle_stop (clearpc' st') (clearprog' cc) net = st'' \<Longrightarrow> 
    elle_alt_sem t cp cc net st st''"
(* instruction in the middle *)
| "\<And> t cp x e i cc net cp' st st' st''.
    ll_get_node t cp = Some (x, L e i) \<Longrightarrow>
    cp_next t cp = Some cp' \<Longrightarrow>
    elle_instD' i (setprog' cc bogus_prog) net (clearpc' st) = st' \<Longrightarrow>
    elle_alt_sem t cp' cc net st' st'' \<Longrightarrow>
    elle_alt_sem t cp cc net st st''"
(* last node is a label *)
| "\<And> t cp x e d cc net st st' st''.
    ll_get_node t cp = Some (x, LLab e d) \<Longrightarrow>
    cp_next t cp = None \<Longrightarrow>
    elle_labD' (clearprog' cc) net (clearpc' st) = st' \<Longrightarrow>
    elle_stop (clearpc' st') (clearprog' cc) net = st'' \<Longrightarrow> 
    elle_alt_sem t cp cc net st st''"
(* label in the middle *)
| "\<And> t cp x e d cp' cc net st st'.
    ll_get_node t cp = Some (x, LLab e d) \<Longrightarrow>
    cp_next t cp = Some cp' \<Longrightarrow>
    elle_labD' (setprog' cc bogus_prog) net (clearpc' st) = st' \<Longrightarrow>
    elle_alt_sem t cp' cc net st' st'' \<Longrightarrow>
    elle_alt_sem t cp  cc net st st''"
(* jump - perhaps worth double checking *)
(* note that this and jmpI cases do not allow us to resolve jumps at the
root. this limitation doesn't really matter in practice as we can just
wrap in a Seq []. (or do we even need that now? ) *)
| "\<And> t cpre cj xj ej dj nj cl cc net st st' st''.
    ll_get_node t (cpre@cj) = Some (xj, LJmp ej dj nj) \<Longrightarrow>
    dj + 1 = length cj \<Longrightarrow>
    ll_get_node t (cpre@cl) = Some (xl, LLab el dl) \<Longrightarrow>
    dl + 1 = length cl \<Longrightarrow>
    elle_jumpD' (setprog' cc bogus_prog) net (clearpc' st) = st' \<Longrightarrow>
    elle_alt_sem t (cpre@cl) cc net st' st'' \<Longrightarrow>
    elle_alt_sem t (cpre@cj) cc net st st''"
(* jmpI, jump taken *)
| "\<And> t cpre cj xj ej dj nj cl cc net st st' st''.
    ll_get_node t (cpre@cj) = Some (xj, LJmpI ej dj nj) \<Longrightarrow>
    dj + 1 = length cj \<Longrightarrow>
    ll_get_node t (cpre@cl) = Some (xl, LLab el dl) \<Longrightarrow>
    dl + 1 = length cl \<Longrightarrow>
    elle_jumpiD' (setprog' cc bogus_prog) net (clearpc' st) = (True, st') \<Longrightarrow>
    elle_alt_sem t (cpre@cl) cc net st' st'' \<Longrightarrow>
    elle_alt_sem t (cpre@cj) cc net st st''"
(* jmpI, jump not taken, at end *)
| "\<And> t cp x e d n cc net st st' st''.
    ll_get_node t cp = Some (x, LJmpI e d n) \<Longrightarrow>
    cp_next t cp = None \<Longrightarrow>
    elle_jumpiD' (setprog' cc bogus_prog) net (clearpc' st) = (False, st') \<Longrightarrow>
    elle_stop (clearpc' st') (clearprog' cc) net = st'' \<Longrightarrow> 
    elle_alt_sem t cp cc net st st''"
(* jmpI, jump not taken, in middle *)
| "\<And> t cp x e d n cp' cc net st st'.
    ll_get_node t cp = Some (x, LJmpI e d n) \<Longrightarrow>
    cp_next t cp = Some cp' \<Longrightarrow>
    elle_jumpiD' (setprog' cc bogus_prog) net (clearpc' st) = (False, st') \<Longrightarrow>
    elle_alt_sem t cp' cc net st' st'' \<Longrightarrow>
    elle_alt_sem t cp cc net st st''"
(* empty sequence, end *)
(* should this have the same semantics as STOP ? yes, i think so*)
| "\<And> t cp cc net x e st st'.
    ll_get_node t cp = Some (x, LSeq e []) \<Longrightarrow>
    cp_next t cp = None \<Longrightarrow> 
    elle_stop (clearpc' st) (clearprog' cc) net = st' \<Longrightarrow>
    elle_alt_sem t cp cc net st st'"
(* empty sequence, in the middle *)
| "\<And> t cp x e cp' cc net z z'. 
    ll_get_node t cp = Some (x, LSeq e []) \<Longrightarrow>
    cp_next t cp = Some cp' \<Longrightarrow>
    elle_alt_sem t cp' cc net z z' \<Longrightarrow>
    elle_alt_sem t cp cc net z z'"
(* end vs not end *)
(* nonempty sequence *)
| "\<And> t cp x e h rest cc net z z' .
    ll_get_node t cp = Some (x, LSeq e (h#rest)) \<Longrightarrow>
    elle_alt_sem t (cp@[0]) cc net z z' \<Longrightarrow>
    elle_alt_sem t cp cc net z z'"

(*
look up childpath (minus last element) at root
if this is 
*)


(* should go in valid4 *)

lemma validate_jump_targets_spec_jumpi' :
"
  (! l . ll4_validate_jump_targets l t \<longrightarrow>
  (! qj ej idxj sz kj . (t, (qj, LJmpI ej idxj sz), kj) \<in> ll3'_descend \<longrightarrow>
  ((\<exists> qr er ls ql el idxl  . t = (qr, LSeq er ls) \<and> (t, (ql, LLab el idxl), er) \<in> ll3'_descend \<and> 
                 idxj + 1 = length kj \<and> idxl + 1 = length er \<and> fst ql = ej) \<or>
   (? qd ed ls k1 k2 . (t, (qd, LSeq ed ls), k1) \<in> ll3'_descend \<and> 
    ((qd, LSeq ed ls), (qj, LJmpI ej idxj sz), k2) \<in> ll3'_descend \<and>
    kj = k1 @ k2 \<and> idxj + 1 = length k2 \<and>
    ( ? ql el idxl kl . ((qd, LSeq ed ls), (ql, LLab el idxl), ed) \<in> ll3'_descend \<and> 
       idxl + 1 = length ed \<and> fst ql = ej)) \<or>
   (? n . mynth l n = Some ej \<and> length kj + n = idxj) 
  ))) \<and>
(* need to quantify over a prefix of the list here (i think) *)
(* we need to change kj = k1 @ k2, need to offset by list length
this also requires it being nonnil, of course *)
(! q e l pref . ll4_validate_jump_targets l (q, LSeq e (pref@ls)) \<longrightarrow>
  (! qj ej idxj sz kjh kjt . ((q, LSeq e ls), (qj, LJmpI ej idxj sz), kjh#kjt) \<in> ll3'_descend \<longrightarrow>
  ((\<exists> qr  ql el idxl  . ((q, LSeq e (pref@ls)), (ql, LLab el idxl), e) \<in> ll3'_descend \<and> 
                 idxj  = length kjt \<and> idxl + 1 = length e \<and> fst ql = ej) \<or>
   (? qd ed lsd k1 k2 . ((q, LSeq e (pref@ls)), (qd, LSeq ed lsd), k1) \<in> ll3'_descend \<and> 
    ((qd, LSeq ed lsd), (qj, LJmpI ej idxj sz), k2) \<in> ll3'_descend \<and>
    (kjh + length pref)#kjt = k1 @ k2 \<and> idxj + 1 = length k2 \<and>
    ( ? ql el idxl . ((qd, LSeq ed lsd), (ql, LLab el idxl), ed) \<in> ll3'_descend \<and> 
       idxl + 1 = length ed \<and> fst ql = ej)) \<or>
   (? n . mynth l n = Some ej \<and> length (kjh#kjt) + n = idxj) 
  )))
"
proof(induction rule:my_ll_induct)
case (1 q e i)
  then show ?case 
    apply(auto)
    apply(drule_tac ll3_hasdesc, auto)
    done
next
  case (2 q e idx)
  then show ?case
apply(auto)
    apply(drule_tac ll3_hasdesc, auto)
    done
next
  case (3 q e idx n)
  then show ?case
apply(auto)
    apply(drule_tac ll3_hasdesc, auto)
    done
next
  case (4 q e idx n)
  then show ?case
apply(auto)
    apply(drule_tac ll3_hasdesc, auto)
    done
next
  case (5 q e l)
  then show ?case 
(*proof of 5, without prefix *)

    apply(clarsimp)
    apply(case_tac e, clarsimp)
  (* now bogus *)
      apply(drule_tac x = "fst q" in  spec, rotate_tac -1)
      apply(drule_tac x = "snd q" in  spec, rotate_tac -1)
     apply(drule_tac x = "[]" in spec, rotate_tac -1)
     apply(drule_tac x = "la" in spec, rotate_tac -1)
     apply(drule_tac x = "[]" in spec, rotate_tac -1) apply(auto)
      apply(drule_tac x = "a" in  spec, rotate_tac -1)
      apply(drule_tac x = "b" in  spec, rotate_tac -1)
      apply(drule_tac x = "ej" in spec, rotate_tac -1)
apply(drule_tac x = "idxj" in  spec, rotate_tac -1)
      apply(drule_tac x = "sz" in  spec, rotate_tac -1)
    apply(frule_tac ll3_descend_nonnil, auto)
      apply(drule_tac x = "hd" in  spec, rotate_tac -1)
      apply(drule_tac x = "tl" in  spec, rotate_tac -1)
      apply(auto)

     apply(case_tac "ll_get_node_list l (aa#list)", auto)
     apply(rename_tac boo, case_tac boo, auto)
    apply(drule_tac x = "fst q" in  spec, rotate_tac -1)
      apply(drule_tac x = "snd q" in  spec, rotate_tac -1)
     apply(drule_tac x = "aa#list" in spec, rotate_tac -1)
     apply(drule_tac x = "la" in spec, rotate_tac -1)
     apply(drule_tac x = "[]" in spec, rotate_tac -1)
     apply(auto)
      apply(drule_tac x = "a" in  spec, rotate_tac -1)
      apply(drule_tac x = "b" in  spec, rotate_tac -1)
      apply(drule_tac x = "ej" in spec, rotate_tac -1)
apply(drule_tac x = "idxj" in  spec, rotate_tac -1)
     apply(drule_tac x = "sz" in  spec, rotate_tac -1)
    apply(frule_tac ll3_descend_nonnil, auto)
      apply(drule_tac x = "hd" in  spec, rotate_tac -1)
      apply(drule_tac x = "tl" in  spec, rotate_tac -1)
      apply(auto)

     apply(case_tac "ll_get_node_list l (aa#list)", auto)
     apply(rename_tac boo, case_tac boo, auto)
    apply(drule_tac x = "fst q" in  spec, rotate_tac -1)
      apply(drule_tac x = "snd q" in  spec, rotate_tac -1)
     apply(drule_tac x = "aa#list" in spec, rotate_tac -1)
    apply(drule_tac x = "la" in spec, rotate_tac -1)
    apply(drule_tac x = "[]" in spec, rotate_tac -1)
    apply(auto)
      apply(drule_tac x = "a" in  spec, rotate_tac -1)
      apply(drule_tac x = "b" in  spec, rotate_tac -1)
      apply(drule_tac x = "ej" in spec, rotate_tac -1)
apply(drule_tac x = "idxj" in  spec, rotate_tac -1)
    apply(drule_tac x = "sz" in  spec, rotate_tac -1)
    apply(frule_tac ll3_descend_nonnil, auto)

    apply(drule_tac x = "hd" in  spec, rotate_tac -1)
apply(drule_tac x = "tl" in  spec, rotate_tac -1)
    apply(auto)
    apply(drule_tac q = q and e = "aa#list" in ll_descend_eq_l2r_list)
  (* first, prove the two descendents are equal (determinism)
then, easy contradiction*)
    apply(subgoal_tac "ej = ab \<and> el = x21 \<and> bb = ba")
    apply(drule_tac x = bb in spec, rotate_tac -1)
    apply(drule_tac x = el in spec, rotate_tac -1)
    apply(drule_tac x = "length list" in spec, rotate_tac -1)
     apply(auto)
    done
next
  case 6
  then show ?case
    apply(clarsimp)
    apply(drule_tac ll3_hasdesc2, auto)
    done
next
  case (7 h l)
  then show ?case 
    apply(clarsimp)
    apply(case_tac e, auto)
    apply(case_tac kjh, auto)
       apply(drule_tac x = "None#la" in spec, auto) apply(rotate_tac -1)
       apply(frule_tac ll_descend_eq_r2l, auto)
       apply(case_tac kjt, auto)
        apply(case_tac "mynth (None # la) idxj", auto)
        apply(case_tac idxj, auto)
       apply(drule_tac ll_descend_eq_l2r)
apply(drule_tac x = aa in spec, rotate_tac -1)
apply(drule_tac x =ba in spec, rotate_tac -1)
    apply(drule_tac x = ej in spec, rotate_tac -1)
    apply(drule_tac x = idxj in spec, rotate_tac -1)
       apply(drule_tac x = sz in spec, rotate_tac -1)
apply(drule_tac x = "ab#list" in spec, rotate_tac -1)
       apply(auto)
    apply(rule_tac x = ac in exI)
    apply(rule_tac x = bb in exI)
         apply(rule_tac x = er in exI)
         apply(rule_tac x = ls in exI)
         apply(rule_tac x = "[length pref]" in exI)
         apply(auto)
         apply(auto simp add:ll3'_descend.intros)
(* next, length pref cons ... *)

    apply(rule_tac x = ac in exI)
    apply(rule_tac x = bb in exI)
         apply(rule_tac x = ed in exI)
        apply(rule_tac x = ls in exI)
         apply(rule_tac x = "length pref#k1" in exI)
        apply(auto)
    apply(subgoal_tac "(((a, b), llt.LSeq [] (pref @ h # l)),
        ((ac, bb), llt.LSeq ed ls), (0 + length pref) # k1)
       \<in> ll3'_descend")
         apply(rule_tac[2] a = a and b = b in ll_descend_prefix)
         apply(auto)
        apply(rule_tac ll_descend_eq_l2r, auto)
    apply(case_tac h, auto)
        apply(drule_tac k = k1 in ll_descend_eq_r2l) apply(auto)

       apply(case_tac n, auto)

      apply(frule_tac ll_descend_eq_r2l, auto)
      apply(rotate_tac 1)
      apply(drule_tac x = 0 in spec, rotate_tac -1)
      apply(drule_tac x = 0 in spec, rotate_tac -1)
      apply(drule_tac x = "[]" in spec, rotate_tac -1)
    apply(drule_tac x = la in spec, rotate_tac -1)
      apply(drule_tac x = "pref@[h]" in spec, rotate_tac -1) apply(auto)
      apply(drule_tac q = "(0,0)" and e = "[]" in ll_descend_eq_l2r_list)
      apply(drule_tac x = aa in spec, rotate_tac -1)
      apply(drule_tac x = ba in spec, rotate_tac -1)
apply(drule_tac x = ej in spec, rotate_tac -1)
apply(drule_tac x = idxj in spec, rotate_tac -1)
      apply(drule_tac x = sz in spec, rotate_tac -1)
apply(drule_tac x = nat in spec, rotate_tac -1)
apply(drule_tac x = kjt in spec, rotate_tac -1)
      apply(auto)
      apply(rule_tac x = ab in exI)
      apply(rule_tac x = bb in exI)
    apply(rule_tac x = ed in exI)
      apply(rule_tac x = lsd in exI)
      apply(rule_tac x = k1 in exI) apply(auto)
      apply(drule_tac k = k1 in ll3'_descend_relabelq) apply(auto)

     apply(case_tac "ll_get_node_list (pref @ h # l) (ab # list)", auto)
     apply(rename_tac boo, case_tac boo, auto)
     apply(case_tac kjh, auto)
      apply(frule_tac ll_descend_eq_r2l, auto)
    apply(drule_tac x = "Some ac # la" in spec, auto) apply(rotate_tac -1)
      apply(case_tac kjt, auto)
       apply(case_tac "mynth (Some ac # la) idxj", auto)
       apply(case_tac idxj, auto)
      apply(drule_tac ll_descend_eq_l2r) 
      apply(drule_tac x = aa in spec, rotate_tac -1)
  apply(drule_tac x = ba in spec, rotate_tac -1)
  apply(drule_tac x = ej in spec, rotate_tac -1)
  apply(drule_tac x = idxj in spec, rotate_tac -1)
      apply(drule_tac x = sz in spec, rotate_tac -1)
      apply(drule_tac x = "ad#lista" in spec, rotate_tac -1)
      apply(auto)
        apply(rule_tac x = ae in exI)
    apply(rule_tac x = bc in exI)
    apply(rule_tac x = er in exI)
    apply(rule_tac x = ls in exI)
    apply(rule_tac x = "[length pref]" in exI) apply(auto)
    apply(subgoal_tac "(((a, b),
         llt.LSeq (ab # list)
          (pref @ ((ae, bc), llt.LSeq er ls) # l)),
        ((ae, bc), llt.LSeq er ls), [0 + length pref])
       \<in> ll3'_descend")
    apply(rule_tac [2] a = a and b = b in ll_descend_prefix) apply(auto)
    apply(auto simp add:ll3'_descend.intros)
        apply(rule_tac x = ae in exI)
    apply(rule_tac x = bc in exI)
    apply(rule_tac x = ed in exI)
       apply(rule_tac x = ls in exI)
       apply(rule_tac x = "length pref # k1" in exI) apply(auto)
    apply(subgoal_tac "(((a, b), llt.LSeq (ab # list) (pref @ h # l)),
        ((ae, bc), llt.LSeq ed ls), (0 + length pref) # k1)
       \<in> ll3'_descend")
        apply(rule_tac [2] a = a and b = b in ll_descend_prefix) apply(auto)
       apply(rule_tac ll_descend_eq_l2r, auto)
    apply(case_tac h, auto)
    apply(drule_tac k = k1 in ll_descend_eq_r2l)
       apply(auto)

      apply(case_tac n, auto)

    apply(frule_tac ll_descend_eq_r2l, auto)
     apply(rotate_tac 1)
     apply(drule_tac x = 0 in spec, rotate_tac -1)
     apply(drule_tac x = 0 in spec, rotate_tac -1)
     apply(drule_tac x = "ab#list" in spec, rotate_tac -1)
     apply(drule_tac x = "la" in spec, rotate_tac -1)
     apply(drule_tac x = "pref @ [h]" in spec, rotate_tac -1) apply(auto)
     apply(drule_tac x = aa in spec, rotate_tac -1)
     apply(drule_tac x = ba in spec, rotate_tac -1)
    apply(drule_tac x = ej in spec, rotate_tac -1)
    apply(drule_tac x = idxj in spec, rotate_tac -1)
     apply(drule_tac x = sz in spec, rotate_tac -1)
    apply(drule_tac x = nat in spec, rotate_tac -1)
     apply(drule_tac x = kjt in spec, rotate_tac -1)
     apply(drule_tac q = "(0,0)" and e = "(ab # list)" and kh = "nat" in ll_descend_eq_l2r_list)
    apply(auto)
    apply(rule_tac x = ad in exI)
    apply(rule_tac x = bc in exI)
    apply(rule_tac x = ed in exI)
     apply(rule_tac x = lsd in exI)
     apply(rule_tac x = k1 in exI)
     apply(auto)
    apply(rule_tac ll3'_descend_relabelq) apply(auto)

    apply(case_tac "ll_get_node_list (pref @ h # l) (ab # list)", auto)
     apply(rename_tac boo, case_tac boo, auto)
     apply(case_tac kjh, auto)
      apply(frule_tac ll_descend_eq_r2l, auto)
    apply(drule_tac x = "Some ac # la" in spec, auto) apply(rotate_tac -1)
      apply(case_tac kjt, auto)
       apply(case_tac "mynth (Some ac # la) idxj", auto)
      apply(case_tac idxj, auto)
      apply(rotate_tac -4)
      apply(drule_tac x = bb in spec, rotate_tac -1)
    apply(drule_tac x = x21 in spec, rotate_tac -1)
      apply(drule_tac x = "length list" in spec, rotate_tac -1)
    apply(drule_tac q = "(a, b)" and e = "ab#list" in ll_descend_eq_l2r_list) apply(auto)
    apply(drule_tac ll_descend_eq_l2r)
     apply(drule_tac x = aa in spec, rotate_tac -1)
     apply(drule_tac x = ba in spec, rotate_tac -1)
    apply(drule_tac x = ej in spec, rotate_tac -1)
    apply(drule_tac x = idxj in spec, rotate_tac -1)
     apply(drule_tac x = sz in spec, rotate_tac -1)
     apply(drule_tac x = "ad#lista" in spec, rotate_tac -1)
     apply(auto)
       apply(rule_tac x = ae in exI)
       apply(rule_tac x = bc in exI)
       apply(rule_tac x = er in exI)
       apply(rule_tac x = ls in exI)
       apply(rule_tac x = "[length pref]" in exI)
       apply(auto)
    apply(subgoal_tac "(((a, b), llt.LSeq (ab # list) (pref @ ((ae, bc), llt.LSeq er ls) # l)),
        ((ae, bc), llt.LSeq er ls), [0 + length pref])
       \<in> ll3'_descend")
        apply(rule_tac[2] ll_descend_prefix) apply(auto)
       apply(rule_tac ll_descend_eq_l2r, auto)
      apply(rule_tac x = ae in exI)
      apply(rule_tac x = bc in exI)
apply(rule_tac x = ed in exI)
      apply(rule_tac x = ls in exI)
      apply(rule_tac x = "length pref#k1" in exI) apply(auto)
    apply(subgoal_tac "Suc idxl = length ed \<Longrightarrow>
       (((a, b), llt.LSeq (ab # list) (pref @ h # l)), ((ae, bc), llt.LSeq ed ls),
        (0 +length pref) # k1)
       \<in> ll3'_descend")
       apply(rule_tac [2] ll_descend_prefix) apply(auto)
      apply(rule_tac ll_descend_eq_l2r, auto)
    apply(case_tac h) apply(auto)
      apply(drule_tac k = k1 in ll_descend_eq_r2l) apply(auto)
     apply(case_tac n, auto)
    
     apply(rotate_tac 2)
     apply(drule_tac x = bb in spec, rotate_tac -1)
     apply(drule_tac x = x21 in spec, rotate_tac -1)
     apply(drule_tac x = "length list" in spec, rotate_tac -1)
    apply(drule_tac e = "ab#list" and q = "(a,b)" in ll_descend_eq_l2r_list)
    apply(auto)

    apply(frule_tac ll_descend_eq_r2l, auto)
    apply(rotate_tac 1)
     apply(drule_tac x = 0 in spec, rotate_tac -1)
     apply(drule_tac x = 0 in spec, rotate_tac -1)
     apply(drule_tac x = "ab#list" in spec, rotate_tac -1)
    apply(drule_tac x = "la" in spec, rotate_tac -1)
     apply(drule_tac x = "pref @ [h]" in spec, rotate_tac -1) apply(auto)
     apply(drule_tac x = aa in spec, rotate_tac -1)
     apply(drule_tac x = ba in spec, rotate_tac -1)
     apply(drule_tac x = "ej" in spec, rotate_tac -1)
    apply(drule_tac x = "idxj" in spec, rotate_tac -1)
    apply(drule_tac x = "sz" in spec, rotate_tac -1) 
        apply(drule_tac x = "nat" in spec, rotate_tac -1)
    apply(drule_tac x = "kjt" in spec, rotate_tac -1) 
    apply(drule_tac l = l and q = "(0,0)" and e = "ab#list" in ll_descend_eq_l2r_list)
    apply(auto)
     apply(rotate_tac -1)
    apply(frule_tac ll_descend_eq_r2l, auto)
     apply(drule_tac q' = "(a, b)" in ll3'_descend_relabelq) apply(auto)
    apply(rotate_tac 1)
    apply(drule_tac x = bc in spec, rotate_tac -1)
    apply(drule_tac x = el in spec, rotate_tac -1)
     apply(drule_tac x = "length list" in spec, rotate_tac -1)
    apply(auto)

    apply(rule_tac x = ad in exI)
    apply(rule_tac x = bc in exI)
    apply(rule_tac x = ed in exI)
    apply(rule_tac x = lsd in exI)
    apply(rule_tac x = k1 in exI)  
    apply(auto)
    apply(rule_tac ll3'_descend_relabelq)
    apply(auto)
    done
qed

lemma validate_jump_targets_spec_jumpi [rule_format] :
"
(! l . ll4_validate_jump_targets l t \<longrightarrow>
  (! qj ej idxj sz kj . (t, (qj, LJmpI ej idxj sz), kj) \<in> ll3'_descend \<longrightarrow>
  ((\<exists> qr er ls ql el idxl  . t = (qr, LSeq er ls) \<and> (t, (ql, LLab el idxl), er) \<in> ll3'_descend \<and> 
                 idxj + 1 = length kj \<and> idxl + 1 = length er \<and> fst ql = ej) \<or>
   (? qd ed ls k1 k2 . (t, (qd, LSeq ed ls), k1) \<in> ll3'_descend \<and> 
    ((qd, LSeq ed ls), (qj, LJmpI ej idxj sz), k2) \<in> ll3'_descend \<and>
    kj = k1 @ k2 \<and> idxj + 1 = length k2 \<and>
    ( ? ql el idxl kl . ((qd, LSeq ed ls), (ql, LLab el idxl), ed) \<in> ll3'_descend \<and> 
       idxl + 1 = length ed \<and> fst ql = ej)) \<or>
   (? n . mynth l n = Some ej \<and> length kj + n = idxj) 
  )))
"
  apply(insert validate_jump_targets_spec_jumpi')
  apply(auto)
  done


(* need to take into account the fact that PC may be updated *)
lemma elle_alt_sem_halted :
"elle_alt_sem t cp cc net st st' \<Longrightarrow>
  (! x y z . st = InstructionToEnvironment x y z \<longrightarrow>
  st' = InstructionToEnvironment x (y \<lparr> vctx_pc := 0 \<rparr>) (z)
)"
proof(induction rule: elle_alt_sem.induct)
case (1 t cp x e i cc net st st' st'')
  then show ?case
    apply(auto simp add:clearpc'_def)
    done
next
  case (2 t cp x e i cc net cp' st st' st'')
  then show ?case
    apply(auto simp add:clearpc'_def)
    done
next
case (3 t cp x e d cc net st st' st'')
  then show ?case
    apply(auto simp add:clearpc'_def)
    done
next
  case (4 st'' t cp x e d cp' cc net st st')
  then show ?case
    apply(auto simp add:clearpc'_def)
    done
next
  case (5 xl el dl t cpre cj xj ej dj nj cl cc net st st' st'')
  then show ?case 
    apply(auto simp add:clearpc'_def)
    done
next
   case (6 xl el dl t cpre cj xj ej dj nj cl cc net st st' st'')
   then show ?case
   apply(auto simp add:clearpc'_def)
    done
next
case (7 t cp x e d n cc net st st' st'')
  then show ?case
    apply(auto simp add:clearpc'_def)
    done
next
  case (8 st'' t cp x e d n cp' cc net st st')
  then show ?case 
    apply(auto simp add:clearpc'_def)
    done
next
  case (9 t cp cc net x e st st')
  then show ?case
    apply(auto simp add:clearpc'_def)
    done
next
  case (10 t cp x e cp' cc net z z')
  then show ?case
    apply(auto simp add:clearpc'_def)
    done
next
  case (11 t cp x e h rest cc net z z')
  then show ?case
    apply(auto simp add:clearpc'_def)
    done
qed

(*

*)

fun clearprog_cctx :: "constant_ctx \<Rightarrow> constant_ctx" where
"clearprog_cctx e =
  (e \<lparr> cctx_program := empty_program \<rparr>)"

(* TODO: be able to load at an arbitrary position (not just 0)? *)
(* this one seems to have problems with reduction, so I'm not using it *)
fun ll4_load_cctx :: "constant_ctx \<Rightarrow> ll4 \<Rightarrow> constant_ctx" where
"ll4_load_cctx cc t =
  (cc \<lparr> cctx_program := 
        Evm.program_of_lst (codegen' t) ProgramInAvl.program_content_of_lst
      \<rparr>)"

(* based on ProgramList.program_list_of_lst *)
(* idea: here, we validate the STACK sizes *)
(* TODO: separate out the validation phase *)
fun  program_list_of_lst_validate  :: "inst list \<Rightarrow> inst list option"  where 
 " program_list_of_lst_validate [] = Some []"
|" program_list_of_lst_validate (Stack (PUSH_N bytes) # rest) =
    (if length bytes \<le> 0 then None
     else (if length bytes > 32 then None
           else (case program_list_of_lst_validate rest of
                        None \<Rightarrow> None
                      | Some rest' \<Rightarrow> 
                          Some ([Stack (PUSH_N bytes)] @
                            map(\<lambda>x. Unknown x) bytes @ rest'))))"
|" program_list_of_lst_validate (i # rest) = 
    (case program_list_of_lst_validate rest of None \<Rightarrow> None | Some rest' \<Rightarrow> Some (i#rest'))"

(* TODO: will codegen' work correctly on the output of this? *)

(* seeing if the list version is easier to work with *)
(* this one doesn't seem to quite be what we want *)
(*
fun ll4_load_lst_map_cctx :: "constant_ctx \<Rightarrow> ll4 \<Rightarrow> constant_ctx" where
"ll4_load_lst_map_cctx cc t =
  (cc \<lparr> cctx_program := Evm.program_of_lst (codegen' t) (\<lambda> il i . program_map_of_lst 0 il (nat i)) \<rparr>)"
*)
fun ll4_load_lst_cctx :: "constant_ctx \<Rightarrow> ll4 \<Rightarrow> constant_ctx" where
"ll4_load_lst_cctx cc t =
  (cc \<lparr> cctx_program := 
      Evm.program.make (\<lambda> i . index (program_list_of_lst (codegen' t)) (nat i))
                       (length (program_list_of_lst (codegen' t)))\<rparr>)"

(* codegen check checks to make sure stack instructions match their length *)
(* load_lst_validate makes sure there are no pushes <1 or >32 bytes *)
fun ll4_load_lst_validate :: "constant_ctx \<Rightarrow> ll4 \<Rightarrow> constant_ctx option" where
"ll4_load_lst_validate cc t =
  (case codegen'_check t of None \<Rightarrow> None
        | Some tc \<Rightarrow>
          (case program_list_of_lst_validate tc of None \<Rightarrow> None
            | Some l \<Rightarrow> Some (cc \<lparr> cctx_program := 
                                    Evm.program.make (\<lambda> i . index l (nat i))
                                    (length l) \<rparr>)))"

lemma program_list_of_lst_validate_split [rule_format] :
"(! b c . program_list_of_lst_validate (a @ b) = Some c \<longrightarrow>
 (? a' . program_list_of_lst_validate a = Some a' \<and>
  (? b' . program_list_of_lst_validate b = Some b' \<and>
      c = a' @ b')))"
proof(induction a)
case Nil
  then show ?case 
    apply(auto)
    done
next
  case (Cons a b)
  then show ?case 
    apply(auto)
    apply(case_tac a, auto)
                apply(simp split:Option.option.split_asm Option.option.split, auto)
               apply(simp split:Option.option.split_asm Option.option.split, auto)
              apply(simp split:Option.option.split_asm Option.option.split, auto)
             apply(simp split:Option.option.split_asm Option.option.split, auto)
            apply(simp split:Option.option.split_asm Option.option.split, auto)
           apply(simp split:Option.option.split_asm Option.option.split, auto)
          apply(simp split:Option.option.split_asm Option.option.split, auto)
         apply(simp split:Option.option.split_asm Option.option.split, auto)
        apply(simp split:Option.option.split_asm Option.option.split, auto)
    apply(case_tac x10, auto)
          apply(simp split:Option.option.split_asm Option.option.split, auto)

         apply(case_tac x2, auto)
        apply(simp split:Option.option.split_asm Option.option.split, auto)
       apply(simp split:Option.option.split_asm Option.option.split, auto)
      apply(simp split:Option.option.split_asm Option.option.split, auto)
     apply(simp split:Option.option.split_asm Option.option.split, auto)
    apply(simp split:Option.option.split_asm Option.option.split, auto)
    done
qed

fun setpc_ir :: "instruction_result \<Rightarrow> nat \<Rightarrow> instruction_result" where
"setpc_ir ir n =
  irmap (\<lambda> v . v \<lparr> vctx_pc := (int n) \<rparr>) ir"

(* this is the basic idea of the theorem statement
the only thing we need to do is specify the precise
relationship between states - i.e. relationship between the cp that the
semantics is starting from and the pc that the program starts from *)
(*
additional assumption - we need to be valid3', and our first element of the
qvalidity has to be 0
*)
(* program_sem_t appears to be way too slow to execute - perhaps better
to switch back... *)
(* prove this holds for any non-continuing final state
(problem - will we need to make this hold inductively for non-final states?)
(will we have a problem with the hardcoded zero start? maybe we need to
subtract it from the final pc)
 *)
(*
lemma elle_alt_correct :
"elle_alt_sem ((0, sz), (t :: ll4t)) elle_interp cp (ir, cc, net) (ir', cc', net') \<Longrightarrow>
 ((0, sz), t) \<in> ll_valid3' \<Longrightarrow>
 ll4_validate_jump_targets [] ((0,sz),t) \<Longrightarrow>
 program_sem_t (ll4_load_cctx cc ((0,sz),t)) net ir = ir2' \<Longrightarrow>
 setpc_ir ir' 0 = setpc_ir ir2' 0
"
*)
(* Should we use "erreq", which throws away the details of the error *)
(* perhaps the issue is that we are sort of implicitly destructing on
the three-tuple in this inductive statement *)
(* est should probably be a record
  fst \<rightarrow> instruction result
  fst . snd \<rightarrow> cctx
  snd . snd \<rightarrow> net
*)

(* need new predicates: isi2e and iscont *)

fun isi2e :: "instruction_result \<Rightarrow> bool" where
"isi2e (InstructionToEnvironment _ _ _) = True"
| "isi2e _ = False"

definition iscont :: "instruction_result \<Rightarrow> bool" where
"iscont i = (\<not> (isi2e i) )"

(* from examples/termination/RunList *)
(*
theorem program_content_first [simp] :
  "program_map_of_lst 0 (a # lst) 0 = Some a"
apply(cases a)
apply(auto)
apply(subst program_list_content_eq4)
apply(cases "get_stack a")
apply(auto)
done
*)

(* need a couple lemmas about program_map_of_lst *)

(* will it suffice to only consider computations that end in a successful result? 
this seems sketchy, but I guess the idea is "computation suffixes"
*)

lemma qvalid_less' :
"(((a, (t :: ('a, 'b, 'c, 'd, 'e, 'f, 'g) llt)) \<in> ll_valid_q) \<longrightarrow> fst a \<le> snd a) \<and>
 ((((a1, a2), (l:: ('a, 'b, 'c, 'd, 'e, 'f, 'g) ll list)) \<in> ll_validl_q \<longrightarrow> a1 \<le> a2))
"
  apply(induction rule: ll_valid_q_ll_validl_q.induct, auto)
  done

lemma qvalid_less1 :
"((a, (t :: ('a, 'b, 'c, 'd, 'e, 'f, 'g) llt)) \<in> ll_valid_q) \<Longrightarrow> fst a \<le> snd a"
  apply(insert qvalid_less') apply(fastforce)
  done

lemma qvalid_less2 :
"(x, (l :: ('a, 'b, 'c, 'd, 'e, 'f, 'g) ll list)) \<in> ll_validl_q \<Longrightarrow> fst x \<le> snd x"
  apply(insert qvalid_less') apply(case_tac x)
  apply(fastforce)
  done

(* we need to rule out invalid (too long/ too short)
stack instructions *)
(* need additional premise about validity of
jump annotations *)
lemma qvalid_codegen'_check' :
  "(((a, (t :: ll4t)) \<in> ll_valid_q) \<longrightarrow> 
      (! il1 . codegen'_check (a, t) = Some il1 \<longrightarrow>
      (! il2 . program_list_of_lst_validate il1 = Some il2 \<longrightarrow>
      snd a \<ge> fst a \<and> length (il2) = snd a - fst a))) \<and>
 (((a1, a2), (l::  ll4 list)) \<in> ll_validl_q \<longrightarrow> 
      (! ils . List.those (map codegen'_check l) = Some ils \<longrightarrow>
      (! il . program_list_of_lst_validate (List.concat ils) = Some il  \<longrightarrow>
        a2 \<ge> a1 \<and> length il = a2 - a1)))"
proof(induction rule:ll_valid_q_ll_validl_q.induct)
case (1 i x e)
  then show ?case 
    apply(auto)
    apply(case_tac i, auto)
    apply(case_tac x10, auto)
    apply(simp split: if_split_asm)
    done
next
  case (2 x d e)
  then show ?case by auto
next
  case (3 x d e s)
  then show ?case 
    apply(auto)
    done
next
  case (4 x d e s)
  then show ?case
    apply(auto)
    done
next
  case (5 n l n' e)
  then show ?case 
    apply(auto)
     apply(case_tac "those (map codegen'_check l)", auto)
apply(case_tac "those (map codegen'_check l)", auto)
    done
next
  case (6 n)
  then show ?case
    apply(auto)
    done
next
  case (7 n h n' t n'')
  then show ?case 
    apply(auto)
    apply(case_tac "codegen'_check ((n,n'), h)", auto)
     apply(drule_tac program_list_of_lst_validate_split) apply(auto)
    apply(case_tac "codegen'_check ((n, n'), h)", auto)
    apply(drule_tac program_list_of_lst_validate_split) apply(auto)
    done
qed

lemma qvalid_codegen'_check1 [rule_format]:
  "(((a, (t :: ll4t)) \<in> ll_valid_q) \<longrightarrow> 
      (! il1 . codegen'_check (a, t) = Some il1 \<longrightarrow>
      (! il2 . program_list_of_lst_validate il1 = Some il2 \<longrightarrow>
      snd a \<ge> fst a \<and> length (il2) = snd a - fst a)))"
  apply(insert qvalid_codegen'_check')
  apply(fastforce)
  done

lemma qvalid_codegen'_check2 [rule_format]:
  "
 (((a1, a2), (l::  ll4 list)) \<in> ll_validl_q \<longrightarrow> 
      (! ils . List.those (map codegen'_check l) = Some ils \<longrightarrow>
      (! il . program_list_of_lst_validate (List.concat ils) = Some il  \<longrightarrow>
        a2 \<ge> a1 \<and> length il = a2 - a1)))"
  apply(insert qvalid_codegen'_check')
  apply(fastforce)
  done

(* TODO: use descend here? *)

lemma qvalid_desc_bounded' :
"((a, (t :: ('a, 'b, 'c, 'd, 'e, 'f, 'g) llt)) \<in> ll_valid_q \<longrightarrow>
 (! cp nd nd' desc . ll_get_node (a, t) cp = Some ((nd, nd'), desc) \<longrightarrow>
    nd \<ge> fst a \<and> nd' \<le> snd a)) \<and>
  (((al, al'), (l :: ('a, 'b, 'c, 'd, 'e, 'f, 'g) ll list)) \<in> ll_validl_q \<longrightarrow>
    (! n  ac ac' tc. n < length l \<longrightarrow> l ! n = ((ac, ac'), tc) \<longrightarrow>
   (! cp nd nd' desc . 
    ll_get_node ((ac, ac'), tc) cp = Some ((nd, nd'), desc) \<longrightarrow>
    nd \<ge> al \<and> nd' \<le> al')))" 
proof(induction rule:ll_valid_q_ll_validl_q.induct)
case (1 i x e)
  then show ?case apply(auto)
     apply(case_tac cp, auto)
    apply(case_tac cp, auto)
    done
next
  case (2 x d e)
  then show ?case 
    apply(auto)
         apply(case_tac cp, auto)
    apply(case_tac cp, auto)
    done
next
  case (3 x d e s)
  then show ?case
apply(auto)
         apply(case_tac cp, auto)
    apply(case_tac cp, auto)
    done
next
  case (4 x d e s)
  then show ?case
apply(auto)
         apply(case_tac cp, auto)
    apply(case_tac cp, auto)
    done
next
  case (5 n l n' e)
  then show ?case apply(auto)
     apply(case_tac cp, auto)
     apply(frule_tac ll_get_node_len) apply(drule_tac x = a in spec) apply(auto)
     apply(case_tac "index l a", auto)
     apply(frule_tac "ll_get_node_child") apply(auto)
    apply(case_tac cp, auto)
    apply(frule_tac ll_get_node_len)
    apply(drule_tac x = a in spec) apply(auto)
    apply(case_tac "index l a", auto)
    apply(frule_tac "ll_get_node_child", auto)
    done
next
  case (6 n)
  then show ?case by auto
next
  case (7 n h n' t n'')
  then show ?case 
    apply(clarify)
    apply(case_tac na, auto)
      apply(drule_tac x = cp in spec) apply(auto)
      apply(drule_tac qvalid_less2, auto)

     apply(drule_tac x = nat in spec) apply(auto)
     apply(rotate_tac -1)
     apply(drule_tac x = cp in spec, rotate_tac -1)
     apply(auto)
     apply(drule_tac qvalid_less1, auto)

     apply(drule_tac x = nat in spec) apply(auto)
     apply(rotate_tac -1)
     apply(drule_tac x = cp in spec, rotate_tac -1)
     apply(auto)
done
qed

lemma qvalid_desc_bounded1 [rule_format] :
"((a, (t :: ('a, 'b, 'c, 'd, 'e, 'f, 'g) llt)) \<in> ll_valid_q \<longrightarrow>
 (! cp nd nd' desc . ll_get_node (a, t) cp = Some ((nd, nd'), desc) \<longrightarrow>
    nd \<ge> fst a \<and> nd' \<le> snd a))"
  apply(insert qvalid_desc_bounded')
  apply(fastforce)
  done

lemma qvalid_desc_bounded2 [rule_format] :
"
  (((al, al'), (l :: ('a, 'b, 'c, 'd, 'e, 'f, 'g) ll list)) \<in> ll_validl_q \<longrightarrow>
    (! n  ac ac' tc. n < length l \<longrightarrow> l ! n = ((ac, ac'), tc) \<longrightarrow>
   (! cp nd nd' desc . 
    ll_get_node ((ac, ac'), tc) cp = Some ((nd, nd'), desc) \<longrightarrow>
    nd \<ge> al \<and> nd' \<le> al')))"
  apply(insert qvalid_desc_bounded')
  apply(fastforce)
  done


lemma valid3'_qvalid :
"((x,t )  :: ('a, 'b, 'c, 'd, 'e) ll3') \<in> ll_valid3' \<Longrightarrow>
  ((x, t) :: ('a, 'b, 'c, 'd, 'e) ll3') \<in> ll_valid_q"
  apply(induction rule:ll_valid3'.induct)
  apply(auto simp add:ll_valid_q_ll_validl_q.intros)
  done

lemma qvalid_cp_next_None' :
"(((a, (t :: ('a, 'b, 'c, 'd, 'e, 'f, 'g) llt)) \<in> ll_valid_q) \<longrightarrow> 
    (! cp qd td . ll_get_node (a, t) cp = Some (qd, td) \<longrightarrow>
        (cp_next (a, t) cp = None) \<longrightarrow> snd qd = snd a)) \<and>
 ((((a1, a2), (l:: ('a, 'b, 'c, 'd, 'e, 'f, 'g) ll list)) \<in> ll_validl_q \<longrightarrow> 
      (! cp qd td . ll_get_node_list l cp = Some (qd, td) \<longrightarrow>
        (cp_next_list l cp = None) \<longrightarrow> snd qd = a2)))
"
proof(induction rule:ll_valid_q_ll_validl_q.induct)
case (1 i x e)
  then show ?case 
    apply(auto) apply(case_tac cp, auto)
    done
next
  case (2 x d e)
  then show ?case
    apply(auto) apply(case_tac cp, auto)
    done
next
  case (3 x d e s)
  then show ?case
apply(auto) apply(case_tac cp, auto)
    done
next
  case (4 x d e s)
  then show ?case
apply(auto) apply(case_tac cp, auto)
    done
next
  case (5 n l n' e)
  then show ?case 
    apply(auto)
    apply(case_tac cp, auto)
    done
next
  case (6 n)
  then show ?case 
    apply(auto)
    apply(case_tac cp, auto)
    done
next
  case (7 n h n' t n'')
  then show ?case
    apply(auto)
    apply(case_tac cp, auto)
    apply(case_tac aa, auto)
     apply(case_tac t, auto)
      apply(split option.split_asm, auto)
      apply(drule_tac ll_validl_q.cases, auto)
     apply(split option.split_asm, auto)

    apply(case_tac t, auto)
     apply(split option.split_asm, auto)
     apply(rotate_tac 4)
      apply(drule_tac x = "nat#list" in spec, auto)
    apply(case_tac x2, auto)
    apply(drule_tac cp_next_nonnil2, auto)
    done
qed

lemma qvalid_cp_next_None1 [rule_format]:
"(((a, (t :: ('a, 'b, 'c, 'd, 'e, 'f, 'g) llt)) \<in> ll_valid_q) \<longrightarrow> 
    (! cp qd td . ll_get_node (a, t) cp = Some (qd, td) \<longrightarrow>
        (cp_next (a, t) cp = None) \<longrightarrow> snd qd = snd a))"
  apply(insert qvalid_cp_next_None')
  apply(fastforce)
  done

lemma qvalid_cp_next_Some' :
"(((a, (t :: ('a, 'b, 'c, 'd, 'e, 'f, 'g) llt)) \<in> ll_valid_q) \<longrightarrow> 
    (! cp qd td . ll_get_node (a, t) cp = Some (qd, td) \<longrightarrow>
        (! cp' . cp_next (a, t) cp = Some cp' \<longrightarrow> 
                 (? qd' td' . ll_get_node (a, t) cp' = Some (qd', td') \<and>
                              snd qd = fst qd')))) \<and>
 ((((a1, a2), (l:: ('a, 'b, 'c, 'd, 'e, 'f, 'g) ll list)) \<in> ll_validl_q \<longrightarrow> 
      (! cp qd td . ll_get_node_list l cp = Some (qd, td) \<longrightarrow>
        (! cp' . cp_next_list l cp = Some cp' \<longrightarrow>
           (? qd' td' . ll_get_node_list l cp' = Some (qd', td') \<and>
                               snd qd = fst qd')))))
"
proof(induction rule:ll_valid_q_ll_validl_q.induct)
case (1 i x e)
  then show ?case 
    apply(auto) done
next
  case (2 x d e)
  then show ?case
    apply(auto) done
next
  case (3 x d e s)
  then show ?case
apply(auto) done
next
  case (4 x d e s)
  then show ?case
apply(auto) done
next
  case (5 n l n' e)
  then show ?case
    apply(auto)
    apply(case_tac cp, auto) apply(case_tac l, auto)
    apply(drule_tac x = "aa#list" in spec, auto)
    apply(rule_tac x = ba in exI) apply(rule_tac x = td' in exI)
    apply(case_tac cp', auto)
    done
next
  case (6 n)
  then show ?case
    apply(auto)
    done
next
  case (7 n h n' t n'')
  then show ?case
    apply(auto)
    apply(case_tac cp, auto) apply(case_tac aa, auto)
     apply(case_tac t, auto) apply(split option.split_asm) apply(auto)
      apply(drule_tac x  = list in spec, auto)

     apply(split option.split_asm, auto)
      apply(drule_tac qvalid_cp_next_None1) apply(auto)
      apply(drule_tac ll_validl_q.cases, auto)

     apply(drule_tac x = list in spec) apply(auto)

    apply(case_tac t, auto) apply(split option.split_asm, auto)
    apply(case_tac x2, auto)
    apply(rotate_tac -3)
    apply(drule_tac x = "nat#list" in spec, auto)
    done
qed

lemma qvalid_cp_next_Some1 [rule_format] :
"(((a, (t :: ('a, 'b, 'c, 'd, 'e, 'f, 'g) llt)) \<in> ll_valid_q) \<longrightarrow> 
    (! cp qd td . ll_get_node (a, t) cp = Some (qd, td) \<longrightarrow>
        (! cp' . cp_next (a, t) cp = Some cp' \<longrightarrow> 
                 (? qd' td' . ll_get_node (a, t) cp' = Some (qd', td') \<and>
                              snd qd = fst qd'))))"
  apply(insert qvalid_cp_next_Some')
  apply(blast)
  done

(* NB behavior of this function is perhaps counterintuitive
for these purposes we consider a leaf node to be first child of itself *)
(* i don't even know if we need this. *)
fun firstchild :: "('a, 'b, 'c, 'd, 'e, 'f, 'g) ll \<Rightarrow> ('a, 'b, 'c, 'd, 'e, 'f, 'g) ll option"
and firstchild_l :: "('a, 'b, 'c, 'd, 'e, 'f, 'g) ll list \<Rightarrow> ('a, 'b, 'c, 'd, 'e, 'f, 'g) ll option" where
"firstchild (_, LSeq _ ls) = firstchild_l ls"
| "firstchild T = Some T"
| "firstchild_l [] = None"
| "firstchild_l (h#t) =
   (case firstchild h of
         Some hc \<Rightarrow> Some hc
         | None \<Rightarrow> firstchild_l t)"

(* need auxiliary lemma, something like
   if ((targstart, _), t) is descended from root
   then when we pass the root through program_list_of_lst_validate
   if t is not a Seq
   then the instruction at index targstart (using the processed root)
   is equal to t (where t is not a seq)
    We could also define a 'first' function, and use that
    to describe the Seq
    (in fact if we define first appropriately we don't even need a case split
      i think. just let first of any non seq thing be itself
      first of a non-nil seq is first of its head
      first of a nil sequence is ? ? (may make this more complicated))

idea: what if first of a Nil sequence is None
      and first of a sequence is the first of its first non-None argument
      or None, if none are
*)



lemma qvalid_get_node' :
"((((a, (t :: ('a, 'b, 'c, 'd, 'e, 'f, 'g) llt)) \<in> ll_valid_q) \<longrightarrow>
    (! cp ad d . ll_get_node (a, t) cp = Some (ad, d) \<longrightarrow>
    (ad, d) \<in> ll_valid_q)) \<and>
 ((((a1, a2), (l:: ('a, 'b, 'c, 'd, 'e, 'f, 'g) ll list)) \<in> ll_validl_q \<longrightarrow> 
    (! cp ad d . ll_get_node_list l cp = Some (ad, d) \<longrightarrow>
    (ad, d) \<in> ll_valid_q))))"
proof(induction rule:ll_valid_q_ll_validl_q.induct)
case (1 i x e)
  then show ?case 
    apply(auto) apply(case_tac cp, auto simp add:ll_valid_q_ll_validl_q.intros)
    done
next
  case (2 x d e)
  then show ?case 
    apply(auto) apply(case_tac cp, auto simp add:ll_valid_q_ll_validl_q.intros)
done next
  case (3 x d e s)
  then show ?case
    apply(auto) apply(case_tac cp, auto simp add:ll_valid_q_ll_validl_q.intros)
    done
next
  case (4 x d e s)
  then show ?case 
    apply(auto) apply(case_tac cp, auto simp add:ll_valid_q_ll_validl_q.intros)
    done
next
  case (5 n l n' e)
  then show ?case 
    apply(auto) apply(case_tac cp, auto simp add:ll_valid_q_ll_validl_q.intros)
    done
next
  case (6 n)
  then show ?case 
    apply(auto) apply(case_tac cp, auto simp add:ll_valid_q_ll_validl_q.intros)
    done
next
  case (7 n h n' t n'')
  then show ?case 
    apply(auto)
    apply(case_tac cp, auto)
    apply(case_tac aa, auto)
    done
qed

lemma qvalid_get_node1 [rule_format] :
"(((a, (t :: ('a, 'b, 'c, 'd, 'e, 'f, 'g) llt)) \<in> ll_valid_q) \<longrightarrow>
    (! cp ad d . ll_get_node (a, t) cp = Some (ad, d) \<longrightarrow>
    (ad, d) \<in> ll_valid_q))"
  apply(insert qvalid_get_node'[of a t])
  apply(auto)
  done

lemma qvalid_get_node2 [rule_format] :
" ((((a1, a2), (l:: ('a, 'b, 'c, 'd, 'e, 'f, 'g) ll list)) \<in> ll_validl_q \<longrightarrow> 
    (! cp ad d . ll_get_node_list l cp = Some (ad, d) \<longrightarrow>
    (ad, d) \<in> ll_valid_q)))"
  apply(insert qvalid_get_node') apply(fastforce)
  done

lemma inst_code_nonzero :
"length (inst_code i) \<noteq> 0"
  apply(case_tac i, auto)
  apply(case_tac x10, auto)
  apply(case_tac x2, auto)
  apply(case_tac "31 < length list", auto)
  done

inductive ll_empty :: "('a, 'b, 'c, 'd, 'e, 'f, 'g) ll \<Rightarrow> bool" and
          ll_emptyl :: "('a, 'b, 'c, 'd, 'e, 'f, 'g) ll list \<Rightarrow> bool" where
"\<And> l x e . ll_emptyl l \<Longrightarrow> ll_empty (x, LSeq e l)"
| "ll_emptyl []"
| "\<And> h t . ll_empty h \<Longrightarrow> ll_emptyl t \<Longrightarrow> ll_emptyl (h#t)"

lemma ll_qvalid_empty_r2l' :
"(ll_empty (t :: ('a, 'b, 'c, 'd, 'e, 'f, 'g) ll) \<longrightarrow> 
           (t \<in> ll_valid_q \<longrightarrow> (fst (fst t)) = (snd (fst t)))) \<and>
 (ll_emptyl (l ::('a, 'b, 'c, 'd, 'e, 'f, 'g) ll list) \<longrightarrow> 
           (! x x' . ((x, x'), l) \<in> ll_validl_q \<longrightarrow> x = x'))"
proof(induction rule:ll_empty_ll_emptyl.induct)
  case (1 l x e)
  then show ?case
    apply(auto)
    apply(drule_tac ll_valid_q.cases) apply(auto)
    done
next
 case 2
  then show ?case
    apply(auto) apply(drule_tac ll_validl_q.cases, auto)
    done
next
  case (3 h t)
  then show ?case
    apply(auto)
     apply(drule_tac ll_validl_q.cases, auto)
 apply(drule_tac ll_validl_q.cases, auto)
    done
qed

lemma ll_qvalid_empty_r2l2 [rule_format] :
" (ll_emptyl (l ::('a, 'b, 'c, 'd, 'e, 'f, 'g) ll list) \<longrightarrow> 
           (! x x' . ((x, x'), l) \<in> ll_validl_q \<longrightarrow> x = x'))"
  apply(insert ll_qvalid_empty_r2l') apply(fastforce)
  done

lemma ll_qvalid_empty_l2r' :
"(((x, t) :: ('a, 'b, 'c, 'd, 'e, 'f, 'g) ll) \<in> ll_valid_q \<longrightarrow> fst x = snd x \<longrightarrow>
           (ll_empty (x, t))) \<and>
 (((xl, xl'), (l ::('a, 'b, 'c, 'd, 'e, 'f, 'g) ll list)) \<in> ll_validl_q \<longrightarrow> xl = xl' \<longrightarrow>
           (ll_emptyl l))"
proof(induction rule:ll_valid_q_ll_validl_q.induct)
case (1 i x e)
  then show ?case apply(auto)
    apply(case_tac i, auto)
    apply(case_tac x10, auto)
    apply(case_tac x2, auto)
    apply(split if_split_asm) apply(auto)
    done
  next
  case (2 x d e)
  then show ?case 
    apply(auto)
    done
next
  case (3 x d e s)
  then show ?case 
    apply(auto)
    done
next
  case (4 x d e s)
  then show ?case 
    apply(auto)
    done
next
  case (5 n l n' e)
  then show ?case 
    apply(auto)
    apply(auto simp add:ll_empty_ll_emptyl.intros)
    done
next
  case (6 n)
  then show ?case 
    apply(auto simp add:ll_empty_ll_emptyl.intros)
    done
next
  case (7 n h n' t n'')
  then show ?case 
    apply(auto)
       apply(drule_tac qvalid_less1) apply(drule_tac qvalid_less2) apply(auto)
      apply(drule_tac qvalid_less1) apply(drule_tac qvalid_less2) apply(auto)
     apply(drule_tac qvalid_less1) apply(drule_tac qvalid_less2) apply(auto)
    apply(drule_tac qvalid_less1) apply(drule_tac qvalid_less2) apply(auto)
    apply(auto simp add:ll_empty_ll_emptyl.intros)
    done
qed

(* we may need separate lemmas about the "load" function *)

(* TODO: change last line to be about Forall rather than concat? *)
lemma ll_empty_codegen_l2r' :
"(ll_empty (t ::  ll4) \<longrightarrow> 
           (! l' . codegen'_check t = Some l' \<longrightarrow> l' = [])) \<and>
 (ll_emptyl (l :: ll4 list) \<longrightarrow> 
    (! l' . List.those (List.map codegen'_check l) = Some l' \<longrightarrow> List.concat l' = []))
"
proof(induction rule:ll_empty_ll_emptyl.induct)
case (1 l x e)
  then show ?case apply(auto)
    apply(split Option.option.split_asm, auto)
    done
next
  case 2
  then show ?case apply(auto)
    done
next
  case (3 h t)
  then show ?case apply(auto)
    apply(case_tac "codegen'_check h", auto)
    done
qed

lemma ll_empty_codegen_r2l' :
"(codegen'_check (t ::  ll4) = Some [] \<longrightarrow> ll_empty t) \<and>
 (! l' . List.those (List.map codegen'_check l) = Some l' \<longrightarrow> 
    list_forall (\<lambda> x . x = []) l' \<longrightarrow> ll_emptyl l)
"
proof(induction rule:my_ll_induct)
case (1 q e i)
  then show ?case
    apply(auto)
    done
next
  case (2 q e idx)
  then show ?case apply(auto) done
next
  case (3 q e idx n)
  then show ?case apply(auto) done
next
  case (4 q e idx n)
  then show ?case apply(auto) done
next
  case (5 q e l)
  then show ?case apply(auto) 
    apply(split option.split_asm) apply(auto)
    apply(auto simp add:ll_empty_ll_emptyl.intros) done
next
  case 6
then show ?case apply(auto simp add:ll_empty_ll_emptyl.intros) done
next
  case (7 h l)
  then show ?case 
    apply(auto)
     apply(split option.split_asm, auto)
    apply(split option.split_asm, auto)
    apply(auto simp add:ll_empty_ll_emptyl.intros)
    done
qed

lemma ll_empty_codegen_r2l1 [rule_format] :
"(codegen'_check (t ::  ll4) = Some [] \<longrightarrow> ll_empty t)
"
  apply(insert ll_empty_codegen_r2l') apply(auto)
  done


lemma ll_empty_codegen_r2l2 [rule_format] :
"(! l' . List.those (List.map codegen'_check l) = Some l' \<longrightarrow> 
    list_forall (\<lambda> x . x = []) l' \<longrightarrow> ll_emptyl l)
"
  apply(insert ll_empty_codegen_r2l') apply(fastforce)
  done


lemma ll_nil_proglist_l2r :
"program_list_of_lst_validate l = Some [] \<Longrightarrow> l = []"
proof(induction l)
  case Nil
  then show ?case by auto
next
  case (Cons a l)
  then show ?case apply(clarsimp)
  apply(case_tac a, auto)
             apply(split option.split_asm, auto)
             apply(split option.split_asm, auto)
             apply(split option.split_asm, auto)
             apply(split option.split_asm, auto)
            apply(split option.split_asm, auto)
             apply(split option.split_asm, auto)
             apply(split option.split_asm, auto)
             apply(split option.split_asm, auto)
        apply(split option.split_asm, auto)
(* stack *) apply(case_tac x10, auto)
         apply(split option.split_asm, auto)
    apply(case_tac x2, auto) apply(split if_split_asm) apply(auto)
        apply(split option.split_asm, auto)
       apply(split option.split_asm, auto)
      apply(split option.split_asm, auto)
     apply(split option.split_asm, auto)
    apply(split option.split_asm, auto)
    done
qed

lemma ll_cons_proglist_l2r [rule_format] :
"! h t . program_list_of_lst_validate l = Some (h#t) \<longrightarrow> (? t' . l = h#t')"
proof(induction l)
  case Nil
  then show ?case by auto
next
  case (Cons a l)
  then show ?case
    apply(auto)
    apply(case_tac a, auto)
             apply(split option.split_asm, auto)
             apply(split option.split_asm, auto)
             apply(split option.split_asm, auto)
             apply(split option.split_asm, auto)
            apply(split option.split_asm, auto)
             apply(split option.split_asm, auto)
             apply(split option.split_asm, auto)
             apply(split option.split_asm, auto)
        apply(split option.split_asm, auto)
(* stack *) apply(case_tac x10, auto)
         apply(split option.split_asm, auto)
    apply(case_tac x2, auto) apply(split if_split_asm) apply(auto)
        apply(split option.split_asm, auto)
       apply(split option.split_asm, auto)
      apply(split option.split_asm, auto)
     apply(split option.split_asm, auto)
    apply(split option.split_asm, auto)
    done
qed

(* TODO: finish this, this is a crucial next step *)
(* used in the semantics to trick the PC into thinking everything is OK. *)
(* this may have unintended side effects which will need to be debugged *)
(* among other things, need to not allow codesize and extcodesize instructions,
as these depend on already knowing the size of the code segment, which at the
source level we do not *)


(* now we need a swapped version that takes ll_get_node as first premise *)
(* see below for how we use rotate to do this *)

(*
if x2b is program_list_of_lst_validate (codegen' check x)
and (q, d) is a descendent along childpath cp
and let ch' = firstchild (q, d)
then x2b ! (fst q) = ch'
*)

(* do we even need the firstchild thing? *)
(* we aren't handling Seq [Seq []] correctly *)
(* we are doing something wrong here, we should be able to handle
the cases where the code buffer is empty more naturally, i suspect *)
(*
do we need to explicitly say adl < adr? that could possibly
suffice at least for the non-Seq cases
*)
(*
do we need to explicitly talk about program_list_of_lst?
we shouldn't because the head should be the same in either case
but it's possible relying on that makes things harder
*)
(*
lemma program_list_of_lst_validate_correspond' :
"((((a, (t :: ll4t)) \<in> ll_valid_q) \<longrightarrow>
    (! cp adl adr d . ll_get_node (a, t) cp = Some ((adl, adr), d) \<longrightarrow>
    (! il1 . codegen'_check (a,t) = Some il1 \<longrightarrow>
    (! il2 . program_list_of_lst_validate il1 = Some il2 \<longrightarrow>
          (? ilsub . codegen'_check ((adl, adr), d) = Some ilsub \<and>
             (case ilsub of
                   [] \<Rightarrow> adl = adr
                   | ilh # ilt \<Rightarrow> 
                      il2 ! (adl - fst a) = ilh \<and> adl \<ge> fst a)))))))
\<and>

(((((a1, a2), (l :: ll4 list)) \<in> ll_validl_q) \<longrightarrow>
    (! cp adl adr d . ll_get_node_list l cp = Some ((adl, adr), d) \<longrightarrow>
    (* not quite right - need to replace codegen'_check here *)
    (! il1 e . codegen'_check ((a1, a2), LSeq e l) = Some il1 \<longrightarrow>
    (! il2 . program_list_of_lst_validate il1 = Some il2 \<longrightarrow>
          (? ilsub . codegen'_check ((adl, adr), d) = Some (ilsub) \<and>
             (case ilsub of
                   [] \<Rightarrow> adl = adr
                  | ilh#ilt \<Rightarrow> il2 ! (adl - a1) = ilh \<and> adl \<ge> a1)))))))
"*)

(* is this lemma quite what we want? *)
(* maybe we need a more specialized version specific to
ll.L (instructions) *)
(*
have a version of this for empty?
or, characterizing cases where get_node is None?
what if there are multiple instructions in the codegen?
instead of just talking about the head, we should say
"for all i between (fst a) and (snd a)
between (fst d) and (snd d)?
il2 ! (i - fst a) = "

need some additional facts implied by ll_valid_q
about how we will succeed in looking up
(or will this be captured correctly by semantics of (!)
also is this going to deal with PUSHes correctly?

i think we have to call program_list_of_lst_validate on codegen'_check

*)
(*
lemma program_list_of_lst_validate_contents' :
"((((a, (t :: ll4t)) \<in> ll_valid_q) \<longrightarrow>
    (! cp adl adr d . ll_get_node (a, t) cp = Some ((adl, adr), d) \<longrightarrow>
    (! il1 . codegen'_check (a,t) = Some il1 \<longrightarrow>
    (! il2 . program_list_of_lst_validate il1 = Some il2 \<longrightarrow>
      (* may need to be strengthened with
fst a \<le> adl \<le> adr \<le> snd a. leaving out for now for simplicity
  *)
          (? ild . codegen'_check ((adl, adr), d) = Some (ild) \<and>
              (? ild2 . program_list_of_lst_validate ild = ild2 \<and>
              (! idx . idx \<ge> adl - fst a \<longrightarrow> 
                       idx \<le> adr - fst a \<longrightarrow>
                       (* still not quite right *)
                       ild2 ! idx = il2 ! (adl - fst a + idx)))))))))
\<and>

(((((a1, a2), (l :: ll4 list)) \<in> ll_validl_q) \<longrightarrow>
    (! cp adl adr d . ll_get_node_list l cp = Some ((adl, adr), d) \<longrightarrow> adr > adl \<longrightarrow>
    (* not quite right - need to replace codegen'_check here *)
    (! il1 e . codegen'_check ((a1, a2), LSeq e l) = Some il1 \<longrightarrow>
    (! il2 . program_list_of_lst_validate il1 = Some il2 \<longrightarrow>
          (? ilh ilt . codegen'_check ((adl, adr), d) = Some (ilh#ilt) \<and>
             il2 ! (adl - a1) = ilh \<and> adl \<ge> a1))))))
"
*)

(* idea behind this next lemma:
- item at the jump location will be a push
- the next item (item located at endloc-1) is going to be a jump
*)
(* to prove this we are going to need

*)
(*
Should we use x instead of q-annotation?
probably doesn't really matter.
*)

lemma output_address_nonnil [rule_format]:
"output_address e \<noteq> []"
proof(induction e)
case 0
  then show ?case 
    apply(auto simp add:output_address_def)
    apply(split prod.split_asm) apply(case_tac x1, auto)
    done
next
  case (Suc e)
  then show ?case
    apply(auto simp add:output_address_def)
    apply(split prod.split_asm)
    apply(split prod.split_asm)
    
    apply(case_tac x1, auto)
     apply(case_tac x1a, auto)
    apply(case_tac x1a, auto)
    done
qed


(*
there is some kind of issue in the case wrhere s = 0
statement about length(ild2)
*)
lemma program_list_of_lst_validate_jmp' :
"((((a, (t :: ll4t)) \<in> ll_valid_q) \<longrightarrow>
    (! cp adl adr e d x . ll_get_node (a, t) cp = Some ((adl, adr), LJmp e d x) (*\<longrightarrow> adr > adl*) \<longrightarrow>
    (! il1 . codegen'_check (a,t) = Some il1 \<longrightarrow>
    (! il2 . program_list_of_lst_validate il1 = Some il2 \<longrightarrow>
          (? ild . codegen'_check ((adl, adr), LJmp e d x) = Some ild \<and>
                   (? ild2 . program_list_of_lst_validate ild = Some ild2 \<and>
                      length il2 > 0 \<and>
                      length il2 = snd a - fst a \<and>
                      length ild2 > 0 \<and>
                      length ild2 = adr - adl (* was fst a *) \<and>
(* facts about length il2 needed? *)
                      ild2 ! 0 = il2 ! (adl - fst a) \<and>
                      ild2 ! (adr - adl - 1) = Pc JUMP \<and> (* is this line right? *)
                      ild2 ! (adr - adl - 1) = il2 ! (adr - fst a - 1)  \<and>
                      adr > 1 \<and> adr > adl \<and>
                      adl \<ge> fst a \<and>
                      adr > fst a)))))))
\<and>

(((((a1, a2), (l :: ll4 list)) \<in> ll_validl_q) \<longrightarrow>
    (! cp adl adr e d x . ll_get_node_list l cp = Some ((adl, adr), LJmp e d x) (*\<longrightarrow> adr > adl*) \<longrightarrow>
    (! il1 eseq . codegen'_check ((a1, a2), LSeq eseq l) = Some il1 \<longrightarrow>
    (! il2 . program_list_of_lst_validate il1 = Some il2 \<longrightarrow>
          (? ild . codegen'_check ((adl, adr), LJmp e d x) = Some ild \<and>
             (? ild2 . program_list_of_lst_validate ild = Some ild2 \<and>
                      length il2 > 0 \<and>
                      length il2 = a2 - a1 \<and> (* wrong i think *)
                      length ild2 > 0 \<and>
                      length ild2 = adr - adl \<and>
                      ild2 ! 0 = il2 ! (adl - a1) \<and>
                      ild2 ! (adr - adl - 1) = Pc JUMP \<and>
                      ild2 ! (adr - adl - 1) =  il2 ! (adr - a1 - 1)  \<and>
                      adr > 1 \<and> adr > adl \<and>
                      adl \<ge> a1 \<and>
                      adr > a1)))))))
"
proof(induction rule:ll_valid_q_ll_validl_q.induct)
case (1 i x e)
  then show ?case 
    apply(clarify)
    apply(case_tac cp, auto)
    done
next
  case (2 x d e)
  then show ?case
apply(clarify)
    apply(case_tac cp, auto)
    done
next
  case (3 x d e s)
  then show ?case
apply(clarify)
    apply(case_tac cp, auto)
    apply(split if_split_asm) apply(auto)
    apply(case_tac "output_address e", auto)
    apply(auto split: if_split_asm)
    apply (metis length_map nth_append_length)
    done
next
  case (4 x d e s)
  then show ?case 
    apply(clarify)
    apply(case_tac cp, auto)
    done
next
  case (5 n l n' e)
  then show ?case
    apply(clarify)
    apply(case_tac cp, auto)
(*
             apply(auto split:option.split_asm)
             apply(drule_tac x = "a#list" in spec, auto)
             apply(auto split: if_split_asm)
          apply(drule_tac x = "a#list" in spec, auto)
          apply(drule_tac x = "adl" in spec)
          apply(drule_tac x = "adr" in spec)
          apply(drule_tac x = e in spec) apply(auto)

          apply(drule_tac x = "a#list" in spec, auto)
          apply(drule_tac x = "adl" in spec)
          apply(drule_tac x = "adr" in spec)
      apply(drule_tac x = e in spec) apply(auto)
           apply(frule_tac qvalid_get_node2) apply(auto)
(* need qvalid_codegen'_check2 *)
           apply(frule_tac qvalid_codegen'_check2, auto)

          apply(drule_tac x = "(a # list)" in spec, auto)

          apply(drule_tac x = "(a # list)" in spec, auto)

        apply(drule_tac x = "(a # list)" in spec, auto)

          apply(drule_tac x = "(a # list)" in spec, auto)
          apply(drule_tac x = "adl" in spec)
          apply(drule_tac x = "adr" in spec)
          apply(drule_tac x = e in spec) apply(auto)

          apply(drule_tac x = "(a # list)" in spec, auto)

          apply(drule_tac x = "(a # list)" in spec, auto)
          apply(drule_tac x = "adl" in spec)
          apply(drule_tac x = "adr" in spec)
          apply(drule_tac x = e in spec) apply(auto)

          apply(drule_tac x = "(a # list)" in spec, auto)
          apply(drule_tac x = "adl" in spec)
          apply(drule_tac x = "adr" in spec)
          apply(drule_tac x = e in spec) apply(auto)

     apply(auto simp add:output_address_nonnil)
*)
    done
next
  case (6 n)
  then show ?case
    apply(clarify)
    apply(case_tac cp, auto)
    done
next
(*
validate_split
codegen'_check
bounded1 *)
  case (7 n h n' t n'')
  then show ?case 
    apply(clarify)
    apply(case_tac cp, clarsimp)
    apply(case_tac a, clarsimp)
     apply(drule_tac x = list in spec)

(* we also probably want to do a similar thing in second case *)
(*    apply(rotate_tac [2] 3) *)
    apply(auto)
                       apply(auto split:option.split_asm)

(*
          apply(drule_tac x = "adl" in spec, rotate_tac -1)
          apply(drule_tac x = "adr" in spec, rotate_tac -1)
     apply(drule_tac x = e in spec, rotate_tac -1)
    apply(drule_tac x = d in spec, rotate_tac -1)
     apply(drule_tac x = x in spec, rotate_tac -1) apply(clarsimp)
*)
    apply(frule_tac program_list_of_lst_validate_split)
     apply(clarsimp)
                       apply(case_tac "length (output_address e) = x", clarsimp)
                        apply(case_tac e, auto) apply(simp add:output_address_def)
                        apply(simp split:prod.split_asm)
    apply(case_tac x1, auto)
                        apply(simp split:prod.split_asm)
                        apply(simp add:output_address_def)
                       apply(auto simp add:output_address_nonnil)

                      apply(simp add:output_address_def)
    apply(frule_tac program_list_of_lst_validate_split)
                      apply(auto)
                        apply(simp split:prod.split_asm)
                      apply(case_tac x1, auto) apply(case_tac x, auto)
    apply(case_tac x, auto)


    apply(frule_tac program_list_of_lst_validate_split)
                     apply(clarsimp)

(* right hand side (n'' - n) seems wrong *)
    apply(frule_tac program_list_of_lst_validate_split)
                        apply(clarsimp)
                        apply(frule_tac qvalid_codegen'_check2) apply(auto)
                        apply(frule_tac qvalid_less1, auto)

    apply(frule_tac program_list_of_lst_validate_split)
                        apply(clarsimp)

    apply(frule_tac program_list_of_lst_validate_split)
                        apply(clarsimp)

                    apply(subgoal_tac "adl - n < length a'")
                     apply(rotate_tac -1) apply(frule_tac a = a' and b = b' in ProgramList.index_append_small)

                        apply(case_tac "index a' (adl - n)", auto)
    apply(frule_tac qvalid_desc_bounded1, auto)

    apply(frule_tac program_list_of_lst_validate_split)
                       apply(clarsimp)

    apply(frule_tac program_list_of_lst_validate_split)
                      apply(clarsimp)

                    apply(subgoal_tac "adr - Suc n < length a'")
                     apply(rotate_tac -1) apply(frule_tac a = a' and b = b' in ProgramList.index_append_small)

                        apply(case_tac "index a' (adr - Suc n)", auto)
                      apply(frule_tac qvalid_desc_bounded1, auto)

    apply(frule_tac program_list_of_lst_validate_split)
                       apply(clarsimp)

    apply(frule_tac program_list_of_lst_validate_split)
                      apply(clarsimp)

    apply(frule_tac program_list_of_lst_validate_split)
                      apply(clarsimp)

    apply(frule_tac program_list_of_lst_validate_split)
                      apply(clarsimp)

    apply(frule_tac program_list_of_lst_validate_split)
                      apply(clarsimp)

                 apply(case_tac " length (output_address e) = x", auto)

    apply(frule_tac program_list_of_lst_validate_split)
                      apply(clarsimp)

    apply(frule_tac program_list_of_lst_validate_split)
                      apply(clarsimp)
    apply(rotate_tac -5)

                apply(drule_tac x = "nat#list" in spec, auto)
                 apply(case_tac " length (output_address e) = x", auto)
                apply(case_tac "output_address e = []", auto)

    apply(frule_tac program_list_of_lst_validate_split)
               apply(clarsimp)
    apply(rotate_tac -5)
                apply(drule_tac x = "nat#list" in spec, auto)
               apply(case_tac " length (output_address e) = x", auto)

    apply(frule_tac program_list_of_lst_validate_split)
               apply(clarsimp)

    apply(frule_tac program_list_of_lst_validate_split)
               apply(clarsimp)
    apply(rotate_tac -5)
                apply(drule_tac x = "nat#list" in spec, auto)
                apply(case_tac "output_address e = []", auto)

             apply(frule_tac qvalid_codegen'_check1) apply(auto)
             apply(frule_tac qvalid_less2, auto)

    apply(rotate_tac -3)
    apply(drule_tac x = "nat#list" in spec, auto)
    apply(frule_tac program_list_of_lst_validate_split)
               apply(clarsimp)
            apply(case_tac "output_address e", auto)
(* good up to here *)
           apply(rotate_tac -3)
           apply(drule_tac x = "nat#list" in spec, auto)
    apply(frule_tac program_list_of_lst_validate_split)
               apply(clarsimp)
           apply(case_tac "output_address e", auto)

(* probably good here *)
(* need to get length a' *)
           apply(frule_tac qvalid_codegen'_check1, clarsimp)
             apply(force) apply(force) apply(simp) apply(clarify)
(* use List.nth_append_length_plus *)
           apply(subgoal_tac "(a' @ b') ! (length a' + (adl - n')) = b' ! (adl - n')")
            apply(rule_tac[2] List.nth_append_length_plus)
           apply(auto)

          apply(rotate_tac -3)
           apply(drule_tac x = "nat#list" in spec, auto)
    apply(frule_tac program_list_of_lst_validate_split)
               apply(clarsimp)
          apply(case_tac "output_address e", auto)

          apply(rotate_tac -3)
           apply(drule_tac x = "nat#list" in spec, auto)
    apply(frule_tac program_list_of_lst_validate_split)
               apply(clarsimp)
         apply(case_tac "output_address e", auto)
           apply(frule_tac qvalid_codegen'_check1, clarsimp)
           apply(force) apply(force) apply(simp) apply(clarify)

           apply(subgoal_tac "(a' @ b') ! (length a' + (adr - n' - 1)) = b' ! (adr - n' -1)")
            apply(rule_tac[2] List.nth_append_length_plus)
         apply(auto)

          apply(rotate_tac -3)
        apply(drule_tac x = "nat#list" in spec, auto)
    apply(frule_tac program_list_of_lst_validate_split)
        apply(clarsimp)

          apply(rotate_tac -3)
        apply(drule_tac x = "nat#list" in spec, auto)
    apply(frule_tac program_list_of_lst_validate_split)
        apply(clarsimp)

          apply(rotate_tac -3)
        apply(drule_tac x = "nat#list" in spec, auto)
    apply(frule_tac program_list_of_lst_validate_split)
        apply(clarsimp)
          apply(case_tac "output_address e", auto)
      apply(frule_tac qvalid_less1, auto)

          apply(rotate_tac -3)
        apply(drule_tac x = "nat#list" in spec, auto)
    apply(frule_tac program_list_of_lst_validate_split)
        apply(clarsimp)
          apply(case_tac "output_address e", auto)
     apply(frule_tac qvalid_less1, auto)

          apply(rotate_tac -3)
        apply(drule_tac x = "nat#list" in spec, auto)
    apply(frule_tac program_list_of_lst_validate_split)
        apply(clarsimp)
          apply(case_tac "length (output_address e) = x", auto)
    done
qed

lemma program_list_of_lst_validate_jmp1 [rule_format]:
"((((a, (t :: ll4t)) \<in> ll_valid_q) \<longrightarrow>
    (! cp adl adr e d x . ll_get_node (a, t) cp = Some ((adl, adr), LJmp e d x) (*\<longrightarrow> adr > adl*) \<longrightarrow>
    (! il1 . codegen'_check (a,t) = Some il1 \<longrightarrow>
    (! il2 . program_list_of_lst_validate il1 = Some il2 \<longrightarrow>
          (? ild . codegen'_check ((adl, adr), LJmp e d x) = Some ild \<and>
                   (? ild2 . program_list_of_lst_validate ild = Some ild2 \<and>
                      length il2 > 0 \<and>
                      length il2 = snd a - fst a \<and>
                      length ild2 > 0 \<and>
                      length ild2 = adr - adl (* was fst a *) \<and>
(* facts about length il2 needed? *)
                      ild2 ! 0 = il2 ! (adl - fst a) \<and>
                      ild2 ! (adr - adl - 1) = Pc JUMP \<and> (* is this line right? *)
                      ild2 ! (adr - adl - 1) = il2 ! (adr - fst a - 1)  \<and>
                      adr > 1 \<and> adr > adl \<and>
                      adl \<ge> fst a \<and>
                      adr > fst a)))))))"
  apply(insert program_list_of_lst_validate_jmp')
  apply(force)
  done


(*
there is some kind of issue in the case wrhere s = 0
statement about length(ild2)
*)
lemma program_list_of_lst_validate_jmpi' :
"((((a, (t :: ll4t)) \<in> ll_valid_q) \<longrightarrow>
    (! cp adl adr e d x . ll_get_node (a, t) cp = Some ((adl, adr), LJmpI e d x) (*\<longrightarrow> adr > adl*) \<longrightarrow>
    (! il1 . codegen'_check (a,t) = Some il1 \<longrightarrow>
    (! il2 . program_list_of_lst_validate il1 = Some il2 \<longrightarrow>
          (? ild . codegen'_check ((adl, adr), LJmpI e d x) = Some ild \<and>
                   (? ild2 . program_list_of_lst_validate ild = Some ild2 \<and>
                      length il2 > 0 \<and>
                      length il2 = snd a - fst a \<and>
                      length ild2 > 0 \<and>
                      length ild2 = adr - adl (* was fst a *) \<and>
(* facts about length il2 needed? *)
                      ild2 ! 0 = il2 ! (adl - fst a) \<and>
                      ild2 ! (adr - adl - 1) = Pc JUMPI \<and> (* is this line right? *)
                      ild2 ! (adr - adl - 1) = il2 ! (adr - fst a - 1)  \<and>
                      adr > 1 \<and> adr > adl \<and>
                      adl \<ge> fst a \<and>
                      adr > fst a)))))))
\<and>

(((((a1, a2), (l :: ll4 list)) \<in> ll_validl_q) \<longrightarrow>
    (! cp adl adr e d x . ll_get_node_list l cp = Some ((adl, adr), LJmpI e d x) (*\<longrightarrow> adr > adl*) \<longrightarrow>
    (! il1 eseq . codegen'_check ((a1, a2), LSeq eseq l) = Some il1 \<longrightarrow>
    (! il2 . program_list_of_lst_validate il1 = Some il2 \<longrightarrow>
          (? ild . codegen'_check ((adl, adr), LJmpI e d x) = Some ild \<and>
             (? ild2 . program_list_of_lst_validate ild = Some ild2 \<and>
                      length il2 > 0 \<and>
                      length il2 = a2 - a1 \<and> (* wrong i think *)
                      length ild2 > 0 \<and>
                      length ild2 = adr - adl \<and>
                      ild2 ! 0 = il2 ! (adl - a1) \<and>
                      ild2 ! (adr - adl - 1) = Pc JUMPI \<and>
                      ild2 ! (adr - adl - 1) =  il2 ! (adr - a1 - 1)  \<and>
                      adr > 1 \<and> adr > adl \<and>
                      adl \<ge> a1 \<and>
                      adr > a1)))))))
"
proof(induction rule:ll_valid_q_ll_validl_q.induct)
case (1 i x e)
  then show ?case 
    apply(clarify)
    apply(case_tac cp, auto)
    done
next
  case (2 x d e)
  then show ?case
apply(clarify)
    apply(case_tac cp, auto)
    done
next
  case (3 x d e s)
  then show ?case
apply(clarify)
    apply(case_tac cp, auto)
    done
next
  case (4 x d e s)
  then show ?case 
    apply(clarify)
    apply(case_tac cp, auto)

    apply(split if_split_asm) apply(auto)
    apply(case_tac "output_address e", auto)
    apply(auto split: if_split_asm)
    apply (metis length_map nth_append_length)
    done
next
  case (5 n l n' e)
  then show ?case
    apply(clarify)
    apply(case_tac cp, auto)
(*
             apply(auto split:option.split_asm)
             apply(drule_tac x = "a#list" in spec, auto)
             apply(auto split: if_split_asm)
          apply(drule_tac x = "a#list" in spec, auto)
          apply(drule_tac x = "adl" in spec)
          apply(drule_tac x = "adr" in spec)
          apply(drule_tac x = e in spec) apply(auto)

          apply(drule_tac x = "a#list" in spec, auto)
          apply(drule_tac x = "adl" in spec)
          apply(drule_tac x = "adr" in spec)
      apply(drule_tac x = e in spec) apply(auto)
           apply(frule_tac qvalid_get_node2) apply(auto)
(* need qvalid_codegen'_check2 *)
           apply(frule_tac qvalid_codegen'_check2, auto)

          apply(drule_tac x = "(a # list)" in spec, auto)

          apply(drule_tac x = "(a # list)" in spec, auto)

        apply(drule_tac x = "(a # list)" in spec, auto)

          apply(drule_tac x = "(a # list)" in spec, auto)
          apply(drule_tac x = "adl" in spec)
          apply(drule_tac x = "adr" in spec)
          apply(drule_tac x = e in spec) apply(auto)

          apply(drule_tac x = "(a # list)" in spec, auto)

          apply(drule_tac x = "(a # list)" in spec, auto)
          apply(drule_tac x = "adl" in spec)
          apply(drule_tac x = "adr" in spec)
          apply(drule_tac x = e in spec) apply(auto)

          apply(drule_tac x = "(a # list)" in spec, auto)
          apply(drule_tac x = "adl" in spec)
          apply(drule_tac x = "adr" in spec)
          apply(drule_tac x = e in spec) apply(auto)

     apply(auto simp add:output_address_nonnil)
*)
    done
next
  case (6 n)
  then show ?case
    apply(clarify)
    apply(case_tac cp, auto)
    done
next
(*
validate_split
codegen'_check
bounded1 *)
  case (7 n h n' t n'')
  then show ?case 
    apply(clarify)
    apply(case_tac cp, clarsimp)
    apply(case_tac a, clarsimp)
     apply(drule_tac x = list in spec)

(* we also probably want to do a similar thing in second case *)
(*    apply(rotate_tac [2] 3) *)
    apply(auto)
                       apply(auto split:option.split_asm)

(*
          apply(drule_tac x = "adl" in spec, rotate_tac -1)
          apply(drule_tac x = "adr" in spec, rotate_tac -1)
     apply(drule_tac x = e in spec, rotate_tac -1)
    apply(drule_tac x = d in spec, rotate_tac -1)
     apply(drule_tac x = x in spec, rotate_tac -1) apply(clarsimp)
*)
    apply(frule_tac program_list_of_lst_validate_split)
     apply(clarsimp)
                       apply(case_tac "length (output_address e) = x", clarsimp)
                        apply(case_tac e, auto) apply(simp add:output_address_def)
                        apply(simp split:prod.split_asm)
    apply(case_tac x1, auto)
                        apply(simp split:prod.split_asm)
                        apply(simp add:output_address_def)
                       apply(auto simp add:output_address_nonnil)

                      apply(simp add:output_address_def)
    apply(frule_tac program_list_of_lst_validate_split)
                      apply(auto)
                        apply(simp split:prod.split_asm)
                      apply(case_tac x1, auto) apply(case_tac x, auto)
    apply(case_tac x, auto)


    apply(frule_tac program_list_of_lst_validate_split)
                     apply(clarsimp)

(* right hand side (n'' - n) seems wrong *)
    apply(frule_tac program_list_of_lst_validate_split)
                        apply(clarsimp)
                        apply(frule_tac qvalid_codegen'_check2) apply(auto)
                        apply(frule_tac qvalid_less1, auto)

    apply(frule_tac program_list_of_lst_validate_split)
                        apply(clarsimp)

    apply(frule_tac program_list_of_lst_validate_split)
                        apply(clarsimp)

                    apply(subgoal_tac "adl - n < length a'")
                     apply(rotate_tac -1) apply(frule_tac a = a' and b = b' in ProgramList.index_append_small)

                        apply(case_tac "index a' (adl - n)", auto)
    apply(frule_tac qvalid_desc_bounded1, auto)

    apply(frule_tac program_list_of_lst_validate_split)
                       apply(clarsimp)

    apply(frule_tac program_list_of_lst_validate_split)
                      apply(clarsimp)

                    apply(subgoal_tac "adr - Suc n < length a'")
                     apply(rotate_tac -1) apply(frule_tac a = a' and b = b' in ProgramList.index_append_small)

                        apply(case_tac "index a' (adr - Suc n)", auto)
                      apply(frule_tac qvalid_desc_bounded1, auto)

    apply(frule_tac program_list_of_lst_validate_split)
                       apply(clarsimp)

    apply(frule_tac program_list_of_lst_validate_split)
                      apply(clarsimp)

    apply(frule_tac program_list_of_lst_validate_split)
                      apply(clarsimp)

    apply(frule_tac program_list_of_lst_validate_split)
                      apply(clarsimp)

    apply(frule_tac program_list_of_lst_validate_split)
                      apply(clarsimp)

                 apply(case_tac " length (output_address e) = x", auto)

    apply(frule_tac program_list_of_lst_validate_split)
                      apply(clarsimp)

    apply(frule_tac program_list_of_lst_validate_split)
                      apply(clarsimp)
    apply(rotate_tac -5)

                apply(drule_tac x = "nat#list" in spec, auto)
                 apply(case_tac " length (output_address e) = x", auto)
                apply(case_tac "output_address e = []", auto)

    apply(frule_tac program_list_of_lst_validate_split)
               apply(clarsimp)
    apply(rotate_tac -5)
                apply(drule_tac x = "nat#list" in spec, auto)
               apply(case_tac " length (output_address e) = x", auto)

    apply(frule_tac program_list_of_lst_validate_split)
               apply(clarsimp)

    apply(frule_tac program_list_of_lst_validate_split)
               apply(clarsimp)
    apply(rotate_tac -5)
                apply(drule_tac x = "nat#list" in spec, auto)
                apply(case_tac "output_address e = []", auto)

             apply(frule_tac qvalid_codegen'_check1) apply(auto)
             apply(frule_tac qvalid_less2, auto)

    apply(rotate_tac -3)
    apply(drule_tac x = "nat#list" in spec, auto)
    apply(frule_tac program_list_of_lst_validate_split)
               apply(clarsimp)
            apply(case_tac "output_address e", auto)
(* good up to here *)
           apply(rotate_tac -3)
           apply(drule_tac x = "nat#list" in spec, auto)
    apply(frule_tac program_list_of_lst_validate_split)
               apply(clarsimp)
           apply(case_tac "output_address e", auto)

(* probably good here *)
(* need to get length a' *)
           apply(frule_tac qvalid_codegen'_check1, clarsimp)
             apply(force) apply(force) apply(simp) apply(clarify)
(* use List.nth_append_length_plus *)
           apply(subgoal_tac "(a' @ b') ! (length a' + (adl - n')) = b' ! (adl - n')")
            apply(rule_tac[2] List.nth_append_length_plus)
           apply(auto)

          apply(rotate_tac -3)
           apply(drule_tac x = "nat#list" in spec, auto)
    apply(frule_tac program_list_of_lst_validate_split)
               apply(clarsimp)
          apply(case_tac "output_address e", auto)

          apply(rotate_tac -3)
           apply(drule_tac x = "nat#list" in spec, auto)
    apply(frule_tac program_list_of_lst_validate_split)
               apply(clarsimp)
         apply(case_tac "output_address e", auto)
           apply(frule_tac qvalid_codegen'_check1, clarsimp)
           apply(force) apply(force) apply(simp) apply(clarify)

           apply(subgoal_tac "(a' @ b') ! (length a' + (adr - n' - 1)) = b' ! (adr - n' -1)")
            apply(rule_tac[2] List.nth_append_length_plus)
         apply(auto)

          apply(rotate_tac -3)
        apply(drule_tac x = "nat#list" in spec, auto)
    apply(frule_tac program_list_of_lst_validate_split)
        apply(clarsimp)

          apply(rotate_tac -3)
        apply(drule_tac x = "nat#list" in spec, auto)
    apply(frule_tac program_list_of_lst_validate_split)
        apply(clarsimp)

          apply(rotate_tac -3)
        apply(drule_tac x = "nat#list" in spec, auto)
    apply(frule_tac program_list_of_lst_validate_split)
        apply(clarsimp)
          apply(case_tac "output_address e", auto)
      apply(frule_tac qvalid_less1, auto)

          apply(rotate_tac -3)
        apply(drule_tac x = "nat#list" in spec, auto)
    apply(frule_tac program_list_of_lst_validate_split)
        apply(clarsimp)
          apply(case_tac "output_address e", auto)
     apply(frule_tac qvalid_less1, auto)

          apply(rotate_tac -3)
        apply(drule_tac x = "nat#list" in spec, auto)
    apply(frule_tac program_list_of_lst_validate_split)
        apply(clarsimp)
          apply(case_tac "length (output_address e) = x", auto)
    done
qed

lemma program_list_of_lst_validate_jmpi1 [rule_format]:
"((((a, (t :: ll4t)) \<in> ll_valid_q) \<longrightarrow>
    (! cp adl adr e d x . ll_get_node (a, t) cp = Some ((adl, adr), LJmpI e d x) (*\<longrightarrow> adr > adl*) \<longrightarrow>
    (! il1 . codegen'_check (a,t) = Some il1 \<longrightarrow>
    (! il2 . program_list_of_lst_validate il1 = Some il2 \<longrightarrow>
          (? ild . codegen'_check ((adl, adr), LJmpI e d x) = Some ild \<and>
                   (? ild2 . program_list_of_lst_validate ild = Some ild2 \<and>
                      length il2 > 0 \<and>
                      length il2 = snd a - fst a \<and>
                      length ild2 > 0 \<and>
                      length ild2 = adr - adl (* was fst a *) \<and>
(* facts about length il2 needed? *)
                      ild2 ! 0 = il2 ! (adl - fst a) \<and>
                      ild2 ! (adr - adl - 1) = Pc JUMPI \<and> (* is this line right? *)
                      ild2 ! (adr - adl - 1) = il2 ! (adr - fst a - 1)  \<and>
                      adr > 1 \<and> adr > adl \<and>
                      adl \<ge> fst a \<and>
                      adr > fst a)))))))"
  apply(insert program_list_of_lst_validate_jmpi')
  apply(force)
  done

lemma program_list_of_lst_validate_head' :
"((((a, (t :: ll4t)) \<in> ll_valid_q) \<longrightarrow>
    (! cp adl adr d . ll_get_node (a, t) cp = Some ((adl, adr), d) \<longrightarrow> adr > adl \<longrightarrow>
    (! il1 . codegen'_check (a,t) = Some il1 \<longrightarrow>
    (! il2 . program_list_of_lst_validate il1 = Some il2 \<longrightarrow>
          (? ilh ilt . codegen'_check ((adl, adr), d) = Some (ilh#ilt) \<and>
              il2 ! (adl - fst a) = ilh \<and> adl \<ge> fst a))))))
\<and>

(((((a1, a2), (l :: ll4 list)) \<in> ll_validl_q) \<longrightarrow>
    (! cp adl adr d . ll_get_node_list l cp = Some ((adl, adr), d) \<longrightarrow> adr > adl \<longrightarrow>
    (* not quite right - need to replace codegen'_check here *)
    (! il1 e . codegen'_check ((a1, a2), LSeq e l) = Some il1 \<longrightarrow>
    (! il2 . program_list_of_lst_validate il1 = Some il2 \<longrightarrow>
          (? ilh ilt . codegen'_check ((adl, adr), d) = Some (ilh#ilt) \<and>
             il2 ! (adl - a1) = ilh \<and> adl \<ge> a1))))))
"
proof(induction rule:ll_valid_q_ll_validl_q.induct)
case (1 i x e)
  then show ?case 
    apply(auto)
    apply(case_tac cp, auto)
    apply(case_tac i, auto) apply(case_tac x10, auto)
    apply(split if_split_asm, auto)
     apply(split if_split_asm, auto)
    apply(case_tac cp, auto)
    done
next
  case (2 x d e)
  then show ?case 
    apply(auto)
     apply(case_tac cp, auto)
apply(case_tac cp, auto)
    done
next
  case (3 x d e s)
  then show ?case
    apply(auto)
     apply(case_tac cp, auto)
apply(case_tac cp, auto)
    done
next
  case (4 x d e s)
  then show ?case
    apply(auto)
     apply(case_tac cp, auto)
apply(case_tac cp, auto)
    done
next
  case (5 n l n' e)
  then show ?case
    apply(clarify) apply(simp)
    apply (split Option.option.split_asm, auto)
    apply(case_tac cp, auto)
    (* problem - now we don't know what the childpath is *)
     apply(case_tac l, auto)
      apply(drule_tac ll_validl_q.cases, auto)
     apply(split Option.option.split_asm, auto)
    (* seems kind of OK here... *)
     apply(drule_tac program_list_of_lst_validate_split) apply(auto)
     apply(frule_tac ll_validl_q.cases, auto)
     apply(case_tac a', auto)
      apply(case_tac b', auto)
       apply(drule_tac ll_nil_proglist_l2r)
apply(drule_tac ll_nil_proglist_l2r) apply(auto)
       apply(drule_tac ll_empty_codegen_r2l1) apply(drule_tac ll_empty_codegen_r2l2) apply(auto)
       apply(subgoal_tac "ll_emptyl (((n, n'a), h)#t)") apply(rule_tac [2] ll_empty_ll_emptyl.intros, auto)
       apply(rotate_tac -1) apply(drule_tac ll_qvalid_empty_r2l2, auto)

      apply(drule_tac ll_nil_proglist_l2r, auto)
      apply(drule_tac ll_cons_proglist_l2r, auto)
     apply(drule_tac ll_cons_proglist_l2r, auto)
    apply(case_tac cp, auto)
    done

next
  case (6 n)
  then show ?case
    apply(clarify)
    apply(case_tac cp, auto)
    done
next
  case (7 n h n' t n'')
  then show ?case 
    apply(clarify)
    apply(case_tac cp, auto)

     apply(split option.split_asm) apply(auto)

      apply(split option.split_asm) apply(auto)
      apply(split option.split_asm) apply(auto)
     apply(split option.split_asm) apply(auto)
     apply(split option.split_asm) apply(auto)
     apply(case_tac a, auto)
      apply(drule_tac x = list in spec) apply(auto)
      apply(drule_tac program_list_of_lst_validate_split)
      apply(auto)
      apply(frule_tac qvalid_codegen'_check1) apply(auto)
    (* to prove: adl \<le> n' (use "bounding" lemma?) *)
    apply(frule_tac qvalid_desc_bounded1) apply(auto)
      apply(subgoal_tac "adl - n < n' - n") apply(auto)
      apply(subst nth_append) apply(auto)

     apply(rotate_tac -4)
     apply(drule_tac x = "nat # list" in spec) apply(auto)
    apply(drule_tac program_list_of_lst_validate_split) apply(auto)
           apply(frule_tac qvalid_codegen'_check1) apply(auto)
     apply(subst nth_append) apply(auto)
                
    apply(split option.split_asm) apply(auto)
     apply(split option.split_asm) apply(auto)
     apply(split option.split_asm) apply(auto)
    apply(split option.split_asm) apply(auto)
    apply(split option.split_asm) apply(auto)
    apply(case_tac a, auto)
     apply(drule_tac qvalid_desc_bounded1, auto)
    apply(frule_tac qvalid_less1, auto)
    apply(rotate_tac -5)
    apply(drule_tac x = "nat#list" in spec) apply(auto)
    apply(drule_tac program_list_of_lst_validate_split) apply(auto)
    done
qed

lemma program_list_of_lst_validate_head1 [rule_format] :
"((((a, (t :: ll4t)) \<in> ll_valid_q) \<longrightarrow>
    (! cp adl adr d . ll_get_node (a, t) cp = Some ((adl, adr), d) \<longrightarrow> adr > adl \<longrightarrow>
    (! il1 . codegen'_check (a,t) = Some il1 \<longrightarrow>
    (! il2 . program_list_of_lst_validate il1 = Some il2 \<longrightarrow>
          (? ilh ilt . codegen'_check ((adl, adr), d) = Some (ilh#ilt) \<and>
              il2 ! (adl - fst a) = ilh \<and> adl \<ge> fst a))))))"
  apply(insert program_list_of_lst_validate_head')
  apply(clarsimp)
  done

lemma ll_validl_snoc [rule_format]:
"! x1 x2 tx1 tx2 t .
   ((x1, x2), (l @ [((tx1, tx2), t)])) \<in> ll_validl_q \<longrightarrow>
   (tx2 = x2 \<and>
    ((x1, tx1), l) \<in> ll_validl_q \<and>
    ((tx1, x2), t) \<in> ll_valid_q)
"
proof(induction l)
case Nil
  then show ?case
    apply(auto)
      apply(drule_tac ll_validl_q.cases, auto)
      apply(drule_tac ll_validl_q.cases, auto)
     apply(drule_tac ll_validl_q.cases, auto)
    apply(rule_tac ll_valid_q_ll_validl_q.intros)
    apply(drule_tac ll_validl_q.cases, auto)
    apply(drule_tac ll_validl_q.cases, auto)
    done
next
  case (Cons a l)
  then show ?case 
    apply(auto)
      apply(drule_tac ll_validl_q.cases, auto)
     apply(drule_tac ll_validl_q.cases, auto)
     apply(drule_tac x = n' in spec)
     apply(drule_tac x = n'' in spec)
     apply(drule_tac x = tx1 in spec)
     apply(drule_tac x = tx2 in spec) 
apply(drule_tac x = t in spec)
     apply(auto simp add:ll_valid_q_ll_validl_q.intros)

    apply(drule_tac ll_validl_q.cases, auto)
  
  done
qed

lemma ll_valid_app [rule_format] :
"! x1 x2 l1 . ((x1, x2), (l1 @ l2)) \<in> ll_validl_q \<longrightarrow>
  (? mid . ((x1, mid), l1) \<in> ll_validl_q \<and>
           ((mid, x2), l2) \<in> ll_validl_q)
"
proof(induction l2)
  case Nil
  then show ?case
    apply(auto) apply(rule_tac x = x2 in exI, auto)
    apply(rule_tac ll_valid_q_ll_validl_q.intros)
    done
next
  case (Cons a l2)
  then show ?case 
    apply(auto) apply(case_tac a, auto)
    apply(drule_tac x = x1 in spec) apply(drule_tac x = x2 in spec)
    apply(drule_tac x = "l1 @ [((aa, b), ba)]" in spec) apply(auto)
    apply(rule_tac x = aa in exI) apply(auto)
     apply(frule_tac ll_validl_snoc, auto)
    apply(frule_tac ll_validl_snoc, auto)
    apply(auto simp add:ll_valid_q_ll_validl_q.intros)
    done
qed

(*
some additional lemmas about non-empty things (using emptiness directly
seems annoying sometimes)
*)
lemma ll_L_valid_bytes_length:
"((x, L e i) \<in> ll_valid_q \<Longrightarrow> fst x < snd x)
"  
  apply(drule_tac ll_valid_q.cases)
       apply(auto)
  apply(subgoal_tac "length (inst_code i) \<noteq> 0") apply(rule_tac[2] inst_code_nonzero)
  apply(auto)
  done


(*
lemma about case where cp_next is None
this means that (if we are a descendent of a qvalid root)
our ending annotation is equal to the overall ending annotation

(we may need a similar lemma characterizing the case where cp_next is Some)
(that is, that our ending annotation is equal to the start annotation of
our cp_next)
*)


(* new proof using list induction... also fails *)
(* we need to rethink this. *)
(*
lemma qvalid_cp_next_None' :
"! x t . (((x, t) :: ('a, 'b, 'c, 'd, 'e, 'f, 'g) ll) \<in> ll_valid_q \<longrightarrow>
  (! xd d pref . ll_get_node (x, t) (pref@cp) = Some (xd, d) \<longrightarrow>
    cp_next (x, t) (pref@cp) = None \<longrightarrow>
    snd x = snd xd))"
proof(induction cp)
  case Nil
  then show ?case 
    apply(auto)
    apply(case_tac "rev suf", auto)
    apply(case_tac "ll_get_node ((a, b), t) (rev list @ [Suc ab])") apply(auto)
    apply(case_tac list, auto)
    sorry
next
  case (Cons a cp)
  then show ?case
    apply(auto)
    apply(case_tac "rev cp @ a # rev pref", auto)
(*    apply(case_tac "rev cp @ [a]", auto) *)
    apply(case_tac " ll_get_node ((aa, b), t) (rev list @ [Suc ab])", auto)
    apply(case_tac list, auto)
    apply(case_tac cp, auto)
    apply(case_tac "ll_get_node ((aa, b), t) (rev lista @ [Suc ac])", auto)

    apply(case_tac lista, auto)
    
     apply(drule_tac x = aa in spec) apply(drule_tac x = b in spec)
     apply(drule_tac x = t in spec) apply(auto)
     apply(drule_tac x = aaa in spec) apply(drule_tac x = ba in spec)
     apply(drule_tac x = d in spec) apply(drule_tac x = "pref @ [a]" in spec) apply(auto)

    apply(case_tac " ll_get_node ((aa, b), t) (rev list @ [Suc ad])", auto)
    apply(case_tac list, auto)

qed
*)
(* old unsuccessful proof using validity induction *)
(* one idea to strengthen - what if we add an additional statement about
all further descendents of d (that if their cp_next is none then what?)
*)


(*
idea: don't use program_map_of_lst?
maybe just use program_list_of_lst with index?
it would be nice to be able to use the "bang" notation,
but maybe LemExtraDefs.index is the way to go?
*)
(*
don't use ll_load_lst_validate
instead create one that defines its program as being
equal to the compiled program
but that seems sketchy, relying on compiled
code to specify source language semantics
*)
(*
another option: use a bogus program for our input such that vctx_advance_pc
will always advance the pc by 1 (of course this will mean nothing)
idea: program is just an infinite stream of noops (?)
*)
lemma silly_eq_fact :
"a = b \<Longrightarrow> c \<noteq> b \<Longrightarrow> a \<noteq> c"

  apply(blast)
  done

(* idea: if instruction i is the nth item in the program
and the PC is equal to i
then one iteration of the EVM (running with fuel=1)
is the same as the instruction result (other than PC)
(problem - need to relate semantics of running EVM
with 1 fuel vs running EVM with higher fuel amounts
(Hoare.execution_continue looks useful))
*)

(*
lemma bytetrunc :
"x < 256 \<Longrightarrow>
 bintrunc 8 x = x
"
(*  apply(simp add:word_ubin. *)
  apply(simp add:bintrunc_def)
  apply(simp add:bin_last_def bin_rest_def)
  apply(case_tac "x mod 2 = 1", simp)
  print_state
  apply(case_tac "x div 2 mod 2 = 1") apply(simp)
  apply(case_tac "(x div 2 div 2 mod 2 = 1)") apply(simp)
     apply(case_tac "(x div 2 div 2 div 2 mod 2 = 1)") apply(simp)
      apply(case_tac "(x div 2 div 2 div 2 div 2 mod 2 = 1)", simp)
       apply(case_tac "(x div 2 div 2 div 2 div 2 div 2 mod 2 = 1)", simp)
        apply(case_tac "(x div 2 div 2 div 2 div 2 div 2 div 2 mod 2 = 1)", simp)
         apply(case_tac "(x div 2 div 2 div 2 div 2 div 2 div 2 div 2 mod 2 = 1)", simp)
  print_state
  print_state
  sorry
*)
(* need to satisfy the premise of this lemma

however, it may be that this is easy, because we
know the integer derives from a 256word

Another thing:
make sure the discrepancy surrounding the
number of bytes in the address is resolved
(may not be important to do at this time)

*)

(*

we may still want the version of the induction principle
from 
http://siek.blogspot.com/2009/11/strong-induction.html

Nat.measure_induct seems to be stated differently in
a way that may be annoying.


*)

lemma my_nat_strong_induct:
  assumes H0 : "P 0"
  and Hless : "(\<And> n . (! j . j < n \<longrightarrow> P j) \<Longrightarrow> P n)"
shows "P (x :: nat)"
proof-
  { fix x
    have "P x"
    proof(induction x)
      case 0
then show ?case using H0 by auto
next
  case (Suc x)
  then show ?case using Hless nat_less_induct
    apply(auto)
    done 
   
  qed
}
  thus ?thesis by auto
qed

definition maxEvmValueN :: nat where
"maxEvmValueN = 115792089237316195423570985008687907853269984665640564039457584007913129639936"

definition maxEvmValueI :: int where
"maxEvmValueI = 115792089237316195423570985008687907853269984665640564039457584007913129639936"

(*
lemma reconstruct_address_assn :
  assumes Acl : "(cl :: nat) < 2 ^ 256"
  shows " cl = (nat (uint (word_of_int (foldl (\<lambda>u. bin_cat u 8) 0 (map uint (output_address cl))) :: 256 word)))"
*)

(* TODO: do I instead need to

*)

(* How much of the problem here lies in the fact that
the version of divmod we are using isn't executable? *)
(* idea: can we generalize to say that cl mod 2^256 is equal to running RHS? *)
(* remove rev from the picture here? prove something about nat_to_bytes'? *)
(* problem: in the recursive case, we don't have
a tight enough bound on value of recursive call
something about length (output_address cl)? 
*)


lemma qvalid_llab :
"(x, LLab e n) \<in> ll_valid_q \<Longrightarrow>
fst x < snd x"
  apply(drule_tac ll_valid_q.cases)
       apply(auto)
  done

lemma mod_really_obvious :
"x = y \<Longrightarrow> z mod x = z mod y"
proof(auto)
qed

lemma my_pow_add :
"(a :: nat) > (b :: nat) \<Longrightarrow>
 (base :: nat) ^ (b) * base ^ (a - b) = base ^ a"  
  apply(subgoal_tac "base ^ (b + (a - b)) = base ^ a")
  apply(insert Power.monoid_mult_class.power_add[of base b "(a - b)"])
  
   apply(auto)
  done

lemma output_address_length_bound [rule_format] :
"(  cl < 256 ^ length (output_address cl))"
proof(induction rule:my_nat_strong_induct[of _ cl])
  case 1
  then show ?case by auto
next
  case (2 n)
  then show ?case 
    apply(auto simp add:output_address_def)
apply(split prod.splits) apply(auto)
    apply(case_tac x1, auto)
     apply(simp add:Divides.divmod_nat_if)
     apply(case_tac "n < 256", auto)
     apply(split prod.split_asm) apply(auto)
     apply(split prod.split_asm) apply(auto)
    apply(split prod.split) apply(auto)
    apply(case_tac x1, auto)
     apply(drule_tac x = "Suc nat" in spec) apply(auto)
     apply(simp add:Divides.divmod_nat_if)
      apply(auto split: if_split_asm prod.splits)

(* this seems maybe ok *)

      apply(simp add:Divides.divmod_nat_def) apply(clarify)
     apply(arith)


    apply(drule_tac x = "Suc nata" in spec) apply(auto)
     apply(simp add:Divides.divmod_nat_def) apply(clarify)
     apply(arith)

     apply(simp add:Divides.divmod_nat_def) apply(clarify)
    apply(arith)
    done
qed


(* generalize argument to bin_cat beyond 8? *)
lemma reconstruct_address_gen [rule_format] :
"(! m . (cl :: nat) mod (2 ^ m) = (nat (bintrunc m (foldl (\<lambda> u . bin_cat u 8) 0 (map uint (output_address cl))))))"
proof(induction rule:my_nat_strong_induct[of _ cl])
  case 1 then show ?case
      apply(simp add:output_address_def) apply(split prod.splits) apply(auto)
    apply(case_tac x1, auto)
     apply(simp add:Divides.divmod_nat_if)
     apply(simp add:byteFromNat_def word8FromNat_def)
    apply(simp add: Divides.divmod_nat_if)
    done

case (2 n)
  then show ?case
    apply(auto)
    apply(case_tac n, auto)
    apply(simp add:output_address_def) apply(split prod.splits) apply(auto)
    apply(case_tac x1, auto)
     apply(simp add:Divides.divmod_nat_if)
     apply(simp add:byteFromNat_def word8FromNat_def)
     apply(simp add: Divides.divmod_nat_if)

    apply(simp add:output_address_def) apply(split prod.splits) apply(auto)
    apply(case_tac x1, auto)
     apply(simp add:byteFromNat_def word8FromNat_def)
(* i think the idea is that we need to deal with wrap around *)

      apply(simp add:uint_word_of_int)
(* need a lemma about results of div *)
(* div_less *)
      apply(simp add:Divides.divmod_nat_def) apply(clarify)
     apply(simp)
     apply(case_tac "m \<le> 8")
      apply(frule_tac Orderings.min_absorb1) apply(simp)
      apply(simp add: bintrunc_mod2p)
      apply (simp add: nat_add_distrib nat_mod_distrib nat_power_eq)

(*
    sledgehammer
      apply(subgoal_tac "2^m dvd 256")
       apply(frule_tac a = "1+ int nata" in mod_mod_cancel) apply(simp)
       apply(simp add: "Divides.nat_mod_distrib")
       apply(simp add: SMT.Suc_as_int)
       apply(subgoal_tac "0 \<le> 2") apply(rotate_tac -1)
    apply(frule_tac n = m in "Int.nat_power_eq")
        apply(simp)
        apply (simp add: nat_add_distrib nat_power_eq)
    apply(simp)
      apply(subgoal_tac "2^m dvd 2^8")
       apply(rule_tac[2] Power.comm_semiring_1_class.le_imp_power_dvd)
       apply(simp) apply(simp)
*)
     apply(subgoal_tac "min m 8 = 8")
    apply(simp)
      apply(simp add: bintrunc_mod2p)
       apply(simp add: "Divides.nat_mod_distrib")
      apply(simp add: SMT.Suc_as_int)
      apply(simp add: Euclidean_Division.div_eq_0_iff)

      apply(subgoal_tac "2^m > (256 :: nat)")
    apply(subgoal_tac "nat (int nata + 1) < (2 ^ m :: nat)")
    apply(clarsimp)
        apply(presburger)
    apply(drule_tac Orderings.order_class.order.strict_trans)
        apply(simp)
       apply(simp)

      apply(auto)
    apply(subgoal_tac "8 < m") apply(rotate_tac -1)
      apply(drule_tac a = 2 in Power.linordered_semidom_class.power_strict_increasing)
       apply(simp)
    apply(simp) apply(simp)

(* final goal *)
(*
     apply(case_tac "Divides.divmod_nat (Suc nataa) 256")
     apply(simp)
(* need this case? *)
     apply(case_tac a) apply(simp_all)

      defer
*)
      apply(simp add: Bits_Int.bintr_cat)
      apply(drule_tac x = "Suc nataa" in spec) apply(auto)
      defer (* easy, mod_less *)

    apply(case_tac "(m :: nat) \<le> 8", simp)
       apply(simp add: Orderings.min_absorb1 Orderings.min_absorb2)
       apply(simp add: Bit_Representation.bintrunc_mod2p)
       apply(simp add: byteFromNat_def word8FromNat_def)
       apply(simp add: Word.uint_word_of_int)

       defer (* easy, m < 8 < 256 *)

       apply(drule_tac x = "m - 8" in spec)       
       apply(simp add: bintrunc_mod2p)
       apply(subgoal_tac "min m 8 = 8") apply(simp)

    apply(subgoal_tac
"
(foldl (\<lambda>u. bin_cat u 8) 0
                      (map uint
                        (rev (case Divides.divmod_nat (Suc nataa) 256 of (0, mo) \<Rightarrow> [byteFromNat mo]
                              | (Suc n, mo) \<Rightarrow> byteFromNat mo # nat_to_bytes' (Suc n)))) mod
                     2 ^ (m - 8)) =
int (Suc nataa mod 2 ^ (m - 8))
"
)
         apply(simp)
    apply(simp add:bin_cat_num)
         apply(simp add: Bit_Representation.bintrunc_mod2p)
         apply(simp add:Divides.divmod_nat_def) apply(auto)
       apply(simp add: byteFromNat_def word8FromNat_def)
       apply(simp add: Word.uint_word_of_int)
       apply(simp add:Divides.zmod_int)

    apply(subgoal_tac "
Suc nata mod ((256 * 2 ^ ((m :: nat) - 8))) = (256 * (Suc nata div 256 mod 2 ^ (m - 8))) + (Suc nata) mod 256
")
        apply(rule_tac [2] mod_mult2_eq)
       apply(subgoal_tac "Suc nata mod (256 * 2 ^ (m - 8)) = Suc nata mod 2 ^ m")
        apply(simp)
        apply(simp add: Int.nat_add_distrib Int.nat_mult_distrib Divides.nat_mod_distrib
                        Int.nat_power_eq)
(* mult2_eq ? should solve it, very nice! *)
       apply(subgoal_tac "m > 8") apply(rotate_tac -1)
        apply(drule_tac base = 2 in my_pow_add) apply(simp)
      apply(simp)
(*
      apply(simp add: div_eq_0_iff)
      apply(subgoal_tac "(2 :: nat) ^ m > 256")
       apply(auto)
*)
     apply(simp add: divmod_nat_def) apply(auto)

     apply(simp add: divmod_nat_def) apply(auto)
        apply(simp add: Int.nat_add_distrib Int.nat_mult_distrib Divides.nat_mod_distrib
                        Int.nat_power_eq)

    apply(subgoal_tac "(2 ^ m) dvd 256")
     apply(drule_tac a = "Suc nata" in Euclidean_Division.euclidean_semiring_cancel_class.mod_mod_cancel)
     apply(simp)
    apply(rotate_tac -2)
    apply(drule_tac a = 2 in Power.comm_semiring_1_class.le_imp_power_dvd)
    apply(simp)
    done
qed

lemma reconstruct_address_gen2 :
"(cl :: nat) mod (2 ^ 256) = (nat ( (foldl (\<lambda> u . bin_cat u 8) 0 (map uint (output_address cl))) mod (2 ^ 256)))"
  apply(insert reconstruct_address_gen[of cl 256])
  apply(simp add:bintrunc_mod2p)
  done

(*
 uint (word_of_int (foldl (\<lambda>u. bin_cat u 8) 0 (map uint (output_address cl)))
*)

(* bintrunc stuff here? *)
(*
lemma reconstruct_address_gen2_int :
"(cl :: int) mod (2 ^ 256) = 
uint (word_of_int (foldl (\<lambda>u. bin_cat u 8) 0 (map uint (output_address cl))))"
  apply(insert reconstruct_address_gen2[of cl])
  apply(simp)
  sorry
*)

(* lemma output_address_bounded :
"length (output_address z) \leq  n \<longrightarrow>
 z \lt 8 ^ n"*)

(* need this one for next one *)
(*
lemma program_list_of_lst_validate_app :
"program_list_of_list (pre@post) = Some result \<Longrightarrow>
 (\exists ppre ppost . result = ppre @ ppost \<and>
    )
*)

lemma program_list_of_lst_validate_unknown :
"
program_list_of_lst_validate (map Unknown ls) = Some (map Unknown ls)"
proof(induction ls)
  case Nil
  then show ?case by auto
next
  case (Cons a ls)
  then show ?case 
    apply(auto)
    done
qed

lemma program_list_of_lst_validate_split2[rule_format] :
"(! b . program_list_of_lst_validate (a @ b) = None \<longrightarrow>
    program_list_of_lst_validate a = None \<or>
    program_list_of_lst_validate b = None)"
proof(induction a)
case Nil
  then show ?case
    apply(auto)
    done
next
  case (Cons a1 a2)
  then show ?case
    apply(auto)
    apply(drule_tac x = b in spec)
    apply(case_tac a1, auto)
     apply(case_tac x10, auto)
    apply(case_tac x10, auto)
    done

qed


(*lemma program_list_of_lst_validate_pushn :
"program_list_of_lst l = Some l' \<Longrightarrow>
 l' ! x = PUSH_N dl \<Longrightarrow>
 length dl < 32 *)
(* make this statement about input instead? *)
(* i think maybe we need to do induction on a list *)
lemma program_list_of_lst_validate_pushn [rule_format] :
"(! l' .  x < length l' \<longrightarrow>
   (! dl . l' ! x = Stack (PUSH_N dl) \<longrightarrow>
(* Some pref @ l' *)
   (! l . program_list_of_lst_validate l = Some (l') \<longrightarrow>
    length dl \<le> 32)))"
proof(induction x)
case 0
  then show ?case 
    apply(simp)
    apply(auto) apply(case_tac l, auto)
    apply(case_tac l', auto)
    apply(case_tac a, auto split:option.split_asm)
    apply(case_tac x10)
      apply(auto split:option.split_asm)
     apply(case_tac x2, auto)
    apply(case_tac x2, auto)
     apply(case_tac "31 < length listb", auto)

    done 
  next
  case (Suc x)
  then show ?case
    apply(clarsimp)
    apply(case_tac l, clarsimp)
    apply(auto)
    apply(subgoal_tac "program_list_of_lst_validate ([a]@list) = Some l'")
     apply(drule_tac program_list_of_lst_validate_split, auto)
    apply(case_tac a', auto)

    apply(case_tac a, simp)
                apply(auto split:option.split_asm)
    apply(case_tac x10, simp)
                apply(auto split:option.split_asm)
     apply(case_tac x2, auto)
     apply(case_tac "31 < length lista", auto)

apply(case_tac a, simp)
                apply(auto split:option.split_asm)
    apply(case_tac x10, simp)
                apply(auto split:option.split_asm)
     apply(case_tac x2, auto)
    apply(case_tac "31 < length listb", auto)

    apply(drule_tac x = "Unknown a # map Unknown listb @ b'" in spec)
    apply(auto)
    apply(drule_tac x = "Unknown a # map Unknown listb @ list" in spec)
    apply(auto)
    apply(case_tac "program_list_of_lst_validate (map Unknown listb @ list)")
     apply(auto)

(* need another splitting lemma for program_list_of_lst_validate *)
     apply(drule_tac program_list_of_lst_validate_split2)
     apply(auto)
     apply(simp add:  program_list_of_lst_validate_unknown)

    apply(drule_tac program_list_of_lst_validate_split)
    apply(auto)
    apply(simp add:  program_list_of_lst_validate_unknown)
    done
qed

(*
next up, we need a lemma to bound the size of addresses output
by output_address based on the length in bytes
(or express in terms of bintrunc?)
(another way of looking at this is to prove that if the
output of output_address is 32 bytes or shorter,
then the input must have been less than 2^32)
*)

(* idea: use clearprog' *)
(* generalize based on whether continuing or ending *)
(* need to add that pc' is equal to targend for valid
trees?
yes - but only if it didn't crash *)
lemma elle_instD'_correct [ rule_format] :

"
inst_valid i \<longrightarrow>
(! cc n vcstart irfinal st2 . elle_instD' i cc n (InstructionContinue vcstart) = irfinal \<longrightarrow>
(! vcstart' . (vcstart \<lparr> vctx_pc := 0 \<rparr>)  = (vcstart' \<lparr> vctx_pc := 0 \<rparr>) \<longrightarrow>
(! cc' . clearprog' cc = clearprog' cc' \<longrightarrow>
    program_content (cctx_program cc') (vctx_pc vcstart') =  Some i \<longrightarrow>
(? irfinal' . ( program_sem (\<lambda> _ . ()) cc' 1 n (InstructionContinue vcstart') = irfinal' \<and>
              clearpc' irfinal = clearpc' irfinal' \<and>
              (! vcfinal' . irfinal' = InstructionContinue vcfinal' \<longrightarrow> vctx_pc (vcfinal') = vctx_pc vcstart' + inst_size i))))))"
proof(cases i)
case (Unknown x1)
  then show ?thesis
  apply(clarify)
  apply(case_tac x1)
      apply(case_tac vcstart, case_tac vcstart', clarsimp) (* experimental line *)

       apply(simp_all add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def
split:list.splits prod.splits instruction_result.splits option.splits )
    done
next
  case (Bits x2)
  then show ?thesis
    apply(clarify)
    apply(case_tac vcstart, case_tac vcstart', clarsimp) (* experimental line *)
    apply(case_tac x2, clarsimp)
    print_state
       apply(simp_all add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def
split:list.splits prod.splits instruction_result.splits option.splits )
    done

next
  case (Sarith x3)
  then show ?thesis
    apply(clarify)
    apply(case_tac vcstart, case_tac vcstart', clarsimp) (* experimental line *)
    apply(case_tac x3, clarsimp)
          apply(simp_all only:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
 split:list.splits prod.splits )
        apply(simp_all)
          apply(simp_all only:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
 split:list.splits prod.splits )
       apply(simp_all)
    done

next
  case (Arith x4)
  then show ?thesis


    apply(clarify)
    apply(case_tac vcstart, case_tac vcstart', case_tac cc, case_tac cc', clarify) (* cc'? *)
    apply(case_tac x4, clarify)
    apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def
split:list.splits prod.splits instruction_result.splits option.splits )
    apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def
split:list.splits prod.splits instruction_result.splits option.splits )
    apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def
split:list.splits prod.splits instruction_result.splits option.splits )
    apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def
split:list.splits prod.splits instruction_result.splits option.splits )
    apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def
split:list.splits prod.splits instruction_result.splits option.splits )
    apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def
split:list.splits prod.splits instruction_result.splits option.splits )
    print_state
    apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def
split:list.splits prod.splits instruction_result.splits option.splits )
         defer (* Exp case is annoying *)
    apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def
split:list.splits prod.splits instruction_result.splits option.splits )
    apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def
split:list.splits prod.splits instruction_result.splits option.splits )
    apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def
split:list.splits prod.splits instruction_result.splits option.splits )
    apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def
split:list.splits prod.splits instruction_result.splits option.splits )
(* sha3 requires sha3_def *)
    apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def
split:list.splits prod.splits instruction_result.splits option.splits )

(* last case: EXP *)
    apply(clarify)
(*    apply(case_tac vctx_stacka) apply(simp)
(*
    apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def
split:list.splits prod.splits instruction_result.splits option.splits )*)
    apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def thirdComponentOfC_def
Gverylow_def Gcopy_def Cmem_def C_def
split:list.splits prod.splits instruction_result.splits option.splits )
*)
apply(simp only:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def mload_def mstore_def mstore8_def cut_memory_def
calldatacopy_def extcodecopy_def
read_word_from_bytes_def ucast_def
variable_ctx.simps
Word.unat_def word_exp.simps
word_of_int_def unat_def
Gverylow_def Gcopy_def Cmem_def C_def
Gexp_def Gexpbyte_def Gmemory_def
vctx_stack_default_def
split:list.splits prod.splits instruction_result.splits option.splits )
    print_state
    apply(safe)
    print_state
apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def mload_def mstore_def mstore8_def cut_memory_def
calldatacopy_def extcodecopy_def
read_word_from_bytes_def ucast_def
variable_ctx.simps
Word.unat_def word_exp.simps
word_of_int_def unat_def
Gverylow_def Gcopy_def Cmem_def C_def
Gexp_def Gexpbyte_def Gmemory_def
vctx_stack_default_def
split:list.splits prod.splits instruction_result.splits option.splits )
    print_state
apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def mload_def mstore_def mstore8_def cut_memory_def
calldatacopy_def extcodecopy_def
read_word_from_bytes_def ucast_def
variable_ctx.simps
Word.unat_def word_exp.simps
word_of_int_def unat_def
Gverylow_def Gcopy_def Cmem_def C_def
Gexp_def Gexpbyte_def Gmemory_def
vctx_stack_default_def
split:list.splits prod.splits instruction_result.splits option.splits )
    print_state
apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def mload_def mstore_def mstore8_def cut_memory_def
calldatacopy_def extcodecopy_def
read_word_from_bytes_def ucast_def
variable_ctx.simps
Word.unat_def word_exp.simps
word_of_int_def unat_def
Gverylow_def Gcopy_def Cmem_def C_def
Gexp_def Gexpbyte_def Gmemory_def
vctx_stack_default_def
split:list.splits prod.splits instruction_result.splits option.splits )
apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def mload_def mstore_def mstore8_def cut_memory_def
calldatacopy_def extcodecopy_def
read_word_from_bytes_def ucast_def
variable_ctx.simps
Word.unat_def word_exp.simps
word_of_int_def unat_def
Gverylow_def Gcopy_def Cmem_def C_def
Gexp_def Gexpbyte_def Gmemory_def
vctx_stack_default_def
split:list.splits prod.splits instruction_result.splits option.splits )
apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def mload_def mstore_def mstore8_def cut_memory_def
calldatacopy_def extcodecopy_def
read_word_from_bytes_def ucast_def
variable_ctx.simps
Word.unat_def word_exp.simps
word_of_int_def unat_def
Gverylow_def Gcopy_def Cmem_def C_def
Gexp_def Gexpbyte_def Gmemory_def
vctx_stack_default_def
split:list.splits prod.splits instruction_result.splits option.splits )
apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def mload_def mstore_def mstore8_def cut_memory_def
calldatacopy_def extcodecopy_def
read_word_from_bytes_def ucast_def
variable_ctx.simps
Word.unat_def word_exp.simps
word_of_int_def unat_def
Gverylow_def Gcopy_def Cmem_def C_def
Gexp_def Gexpbyte_def Gmemory_def
vctx_stack_default_def
split:list.splits prod.splits instruction_result.splits option.splits )
apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def mload_def mstore_def mstore8_def cut_memory_def
calldatacopy_def extcodecopy_def
read_word_from_bytes_def ucast_def
variable_ctx.simps
Word.unat_def word_exp.simps
word_of_int_def unat_def
Gverylow_def Gcopy_def Cmem_def C_def
Gexp_def Gexpbyte_def Gmemory_def
vctx_stack_default_def
split:list.splits prod.splits instruction_result.splits option.splits )
apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def mload_def mstore_def mstore8_def cut_memory_def
calldatacopy_def extcodecopy_def
read_word_from_bytes_def ucast_def
variable_ctx.simps
Word.unat_def word_exp.simps
word_of_int_def unat_def
Gverylow_def Gcopy_def Cmem_def C_def
Gexp_def Gexpbyte_def Gmemory_def
vctx_stack_default_def
split:list.splits prod.splits instruction_result.splits option.splits )
           apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def mload_def mstore_def mstore8_def cut_memory_def
calldatacopy_def extcodecopy_def
read_word_from_bytes_def ucast_def
variable_ctx.simps
Word.unat_def word_exp.simps
word_of_int_def unat_def
Gverylow_def Gcopy_def Cmem_def C_def
Gexp_def Gexpbyte_def Gmemory_def
vctx_stack_default_def
split:list.splits prod.splits instruction_result.splits option.splits )
    print_state
    defer
apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def mload_def mstore_def mstore8_def cut_memory_def
calldatacopy_def extcodecopy_def
read_word_from_bytes_def ucast_def
variable_ctx.simps
Word.unat_def word_exp.simps
word_of_int_def unat_def
Gverylow_def Gcopy_def Cmem_def C_def
Gexp_def Gexpbyte_def Gmemory_def
vctx_stack_default_def
split:list.splits prod.splits instruction_result.splits option.splits )
apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def mload_def mstore_def mstore8_def cut_memory_def
calldatacopy_def extcodecopy_def
read_word_from_bytes_def ucast_def
variable_ctx.simps
Word.unat_def word_exp.simps
word_of_int_def unat_def
Gverylow_def Gcopy_def Cmem_def C_def
Gexp_def Gexpbyte_def Gmemory_def
vctx_stack_default_def
split:list.splits prod.splits instruction_result.splits option.splits )
apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def mload_def mstore_def mstore8_def cut_memory_def
calldatacopy_def extcodecopy_def
read_word_from_bytes_def ucast_def
variable_ctx.simps
Word.unat_def word_exp.simps
word_of_int_def unat_def
Gverylow_def Gcopy_def Cmem_def C_def
Gexp_def Gexpbyte_def Gmemory_def
vctx_stack_default_def
split:list.splits prod.splits instruction_result.splits option.splits )
    print_state
    defer
apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def mload_def mstore_def mstore8_def cut_memory_def
calldatacopy_def extcodecopy_def
read_word_from_bytes_def ucast_def
variable_ctx.simps
Word.unat_def word_exp.simps
word_of_int_def unat_def
Gverylow_def Gcopy_def Cmem_def C_def
Gexp_def Gexpbyte_def Gmemory_def
vctx_stack_default_def
split:list.splits prod.splits instruction_result.splits option.splits )

      apply(rule_tac exI) apply(rule_tac[2] exI) apply(rule_tac[3] exI)

    apply(auto simp only:)


      apply(simp_all only:meter_gas_def subtract_gas.simps check_resources_def variable_ctx.simps) (* NB this affects other goals *)
(* thirdComponentOfC? *)
    print_state
    apply(simp_all del:meter_gas_def check_resources_def thirdComponentOfC_def split:list.splits) (* this may fail *)
    print_state
      apply(auto simp only:) (* test *)
      apply(simp_all only:meter_gas_def subtract_gas.simps check_resources_def variable_ctx.simps) (* NB this affects other goals *)
    apply(simp_all del:meter_gas_def check_resources_def thirdComponentOfC_def split:list.splits) (* this may fail *)
                      apply(auto simp only: split:nat.splits option.splits)
    apply(simp_all del:meter_gas_def check_resources_def thirdComponentOfC_def split:list.splits) (* this may fail *)
    print_state
    apply(auto)
    print_state
apply(auto simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def mload_def mstore_def mstore8_def cut_memory_def
calldatacopy_def extcodecopy_def
read_word_from_bytes_def ucast_def
variable_ctx.simps
Word.unat_def word_exp.simps
word_of_int_def unat_def
Gverylow_def Gcopy_def Cmem_def C_def
Gexp_def Gexpbyte_def Gmemory_def
vctx_stack_default_def
split:list.splits prod.splits instruction_result.splits option.splits )
    
(* more explicit approach to exI below *)
    print_state
    apply(case_tac "int (length vctx_stacka) \<le> 1025 \<and>
           10 + (if vctx_stacka ! Suc 0 = 0 then 0
                 else Gexpbyte n * (1 + log256floor (uint (vctx_stacka ! Suc 0))))
           \<le> vctx_gasa")
       apply(auto split:list.splits)

    apply(case_tac "int (length vctx_stacka) \<le> 1025 \<and>
           10 + (if vctx_stacka ! Suc 0 = 0 then 0
                 else Gexpbyte n * (1 + log256floor (uint (vctx_stacka ! Suc 0))))
           \<le> vctx_gasa")
      apply(auto split:list.splits)

    apply(case_tac "int (length vctx_stacka) \<le> 1025 \<and>
           10 + (if vctx_stacka ! Suc 0 = 0 then 0
                 else Gexpbyte n * (1 + log256floor (uint (vctx_stacka ! Suc 0))))
           \<le> vctx_gasa")
     apply(auto split:list.splits)
    done
next
  case (Info x5)
  then show ?thesis 
(* proof prefix, copied from Arith *)
    apply(clarify)
    apply(case_tac vcstart, case_tac vcstart', case_tac cc, case_tac cc', clarify) (* cc'? *)
    apply(case_tac x5, clarsimp)
    
  apply(simp_all only:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
split:list.splits prod.splits instruction_result.splits ) 
                   apply(simp_all) 
 apply(simp_all only:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
split:list.splits prod.splits instruction_result.splits ) 
                   apply(simp_all) 
    apply(simp add:gas_def)

    done
next
  case (Dup x6)
  then show ?thesis
    apply(clarify)
    apply(case_tac vcstart, case_tac vcstart', case_tac cc, case_tac cc', clarify) (* cc'? *)
    apply(case_tac x6, clarsimp)

  apply(simp_all only:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def
split:list.splits prod.splits instruction_result.splits ) 
                   apply(simp_all) 
apply(simp_all only:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def
split:list.splits prod.splits instruction_result.splits option.splits ) 
                   apply(simp_all) 
    done
next
  case (Memory x7)
  then show ?thesis
    apply(clarify) 
    apply(case_tac vcstart, case_tac vcstart', case_tac cc, case_tac cc', clarify) (* cc'? *)

    apply(case_tac x7, clarify)
    apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def mload_def mstore_def cut_memory_def
read_word_from_bytes_def
split:list.splits prod.splits instruction_result.splits option.splits )
    apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def mload_def mstore_def cut_memory_def
read_word_from_bytes_def
split:list.splits prod.splits instruction_result.splits option.splits )
apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def mload_def mstore_def mstore8_def cut_memory_def
read_word_from_bytes_def ucast_def
variable_ctx.simps
split:list.splits prod.splits instruction_result.splits option.splits )
        apply(clarify)
        apply(safe) apply(simp)
        apply(force)
    print_state
apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def mload_def mstore_def mstore8_def cut_memory_def
calldatacopy_def
read_word_from_bytes_def ucast_def
variable_ctx.simps
split:list.splits prod.splits instruction_result.splits option.splits )
apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def mload_def mstore_def mstore8_def cut_memory_def
calldatacopy_def
read_word_from_bytes_def ucast_def
variable_ctx.simps
split:list.splits prod.splits instruction_result.splits option.splits )
apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def mload_def mstore_def mstore8_def cut_memory_def
calldatacopy_def extcodecopy_def
read_word_from_bytes_def ucast_def
variable_ctx.simps
split:list.splits prod.splits instruction_result.splits option.splits )

(*
    apply(simp only: irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def mload_def mstore_def mstore8_def cut_memory_def
calldatacopy_def extcodecopy_def
read_word_from_bytes_def ucast_def
variable_ctx.simps
split:list.splits prod.splits instruction_result.splits option.splits)*)
(*    apply(simp) (* TODO: changes being made here, was originally just the
simp add line, now too slow *) *)
apply(simp add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def sha3_def mload_def mstore_def mstore8_def cut_memory_def
calldatacopy_def extcodecopy_def
read_word_from_bytes_def ucast_def
variable_ctx.simps
split:list.splits prod.splits instruction_result.splits option.splits )
    done
next
  case (Storage x8)
  then show ?thesis 
    apply(clarify)
    apply(case_tac vcstart, case_tac vcstart', case_tac cc, case_tac cc', clarify) (* cc'? *)
    apply(case_tac x8, simp)
    apply(simp_all add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def
split:list.splits prod.splits instruction_result.splits option.splits )

    apply(auto)
    done
next
  case (Pc x9)
  then show ?thesis
    apply(clarify)
    apply(case_tac vcstart, case_tac vcstart', case_tac cc, case_tac cc', clarify) (* cc'? *)
    apply(case_tac x9, simp)
    apply(simp_all add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def
split:list.splits prod.splits instruction_result.splits option.splits )
    done
next
  case (Stack x10)
  then show ?thesis
    apply(clarify)
    apply(case_tac vcstart, case_tac vcstart', case_tac cc, case_tac cc', clarify) (* cc'? *)
    apply(case_tac x10, simp)
    apply(simp_all add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def
split:list.splits prod.splits instruction_result.splits option.splits )
    done
next
  case (Swap x11)
  then show ?thesis 
    apply(clarify)
    apply(case_tac vcstart, case_tac vcstart', case_tac cc, case_tac cc', clarify) (* cc'? *)
    apply(case_tac x11, simp)
    apply(simp_all add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def
split:list.splits prod.splits instruction_result.splits option.splits )
    done
next
  case (Log x12)
  then show ?thesis
    apply(clarify)
    apply(case_tac vcstart, case_tac vcstart', case_tac cc, case_tac cc', clarify) (* cc'? *)
    apply(simp_all add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def
split:list.splits prod.splits instruction_result.splits option.splits )
    apply(case_tac x12, simp)
    apply(simp_all add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def create_log_entry_def vctx_returned_bytes_def
split:list.splits prod.splits instruction_result.splits option.splits )

    done
next
  case (Misc x13)
  then show ?thesis
    apply(clarify)
    apply(case_tac vcstart, case_tac vcstart', case_tac cc, case_tac cc', clarify) (* cc'? *)
    apply(case_tac x13, simp)
        apply(simp_all add:irmap.simps subtract_gas.simps vctx_advance_pc_def vctx_next_instruction_def
program.defs check_resources_def list.cases clearpc'_def clearprog'_def variable_ctx.defs inst_stack_numbers.simps bits_stack_nums.simps
arith_inst_numbers.simps meter_gas_def elle_instD'.simps new_memory_consumption.simps
gas_def
split:list.splits prod.splits instruction_result.splits option.splits )
        
        apply(clarsimp)
        apply(auto)
        apply(simp add: vctx_returned_bytes_def)
        apply(simp add: vctx_returned_bytes_def)
    done
qed


(* For instruction cases, would it be easier to just prove a lemma that for
any valid instruction, one step of program execution is the same as 1 step of Elle execution? *)

lemma my_exec_continue :
"program_sem stopper cc (Suc f) net st = st'' \<Longrightarrow>
 ( ? st' . program_sem stopper cc 1 net st = st' \<and> program_sem stopper cc f net st' = st'')"
  apply(insert Hoare.execution_continue)
  apply(auto)
  done

(* TODO: need some kind of eliminators for elle_alt_sem (?) *)
(* Do we need to somehow generalize the bottom part by a premise about elle_alt_sem of the tail? *)
(* Idea: restrict to only successful returned results
(not arbitrary InstructionToEnvironment)
*)

lemma check_resources_gen :
"check_resources v c s i net \<Longrightarrow>
 inst_valid i \<Longrightarrow>
 v' = (v \<lparr> vctx_pc := pc' \<rparr>) \<Longrightarrow>
 c' = (c \<lparr> cctx_program := prog' \<rparr>) \<Longrightarrow>
 check_resources v' c' s i net
"
  apply(case_tac i)
              apply(simp add: check_resources_def)
              apply(simp add: check_resources_def)
              apply(simp add: check_resources_def)
              apply(simp add: check_resources_def)
              apply(simp add: check_resources_def)
              apply(simp add: check_resources_def)
              apply(simp add: check_resources_def)
       apply(simp add: check_resources_def)
      apply(simp add: check_resources_def)
              apply(simp add: check_resources_def)
              apply(simp add: check_resources_def)
   apply(simp add: check_resources_def)
   apply(simp add: check_resources_def del:meter_gas_def)
   apply(case_tac x13)
   apply(simp_all add: check_resources_def)
  done

(*
TODO: we also need to prove a case that if the Elle semantics fails,
so must the compiled version, even if the resulting states are not the same

this should not be too hard to add in, but i'm going to focus on
the success cases for now.
*)
(*
idea: prove a separate theorem that says
*)

theorem elle_alt_correct :
"elle_alt_sem ((t :: ll4)) cp cc net st st' \<Longrightarrow>
 (t \<in> ll_valid3' \<longrightarrow>
  (! tend ttree . t = ((0, tend), ttree) \<longrightarrow>
 ll4_validate_jump_targets [] t \<longrightarrow>
 (! targstart targend tdesc . ll_get_node t cp = Some ((targstart, targend), tdesc) \<longrightarrow>
   (! vi . st = InstructionContinue vi \<longrightarrow>
    (* require that prog already be loaded beofre this point? *)
   (! prog . ll4_load_lst_validate cc t = Some prog \<longrightarrow>
   (! act vc venv fuel stopper . program_sem stopper
               prog 
               fuel net 
(* is this arithmetic around fst (fst t) right? *)
(* perhaps we need a secondary proof that validity implies
that targstart will be greater than or equal to fst (fst t) *)
               (setpc_ir st (targstart  (*- fst (fst t) *))) = 
                   (* fuel can be arbitrary, but we require to compute to a final result *)
                   InstructionToEnvironment act vc venv \<longrightarrow>
( ! l . act \<noteq> ContractFail l ) \<longrightarrow> 
                  (* the issue may have to do with distinguishing between errors? *)
                  (* TODO: in some cases we end up having to compare unloaded programs? *)
                  setpc_ir st' 0 = setpc_ir (InstructionToEnvironment act vc venv) 0))))))"
(*  using [[simp_debug]] *)
(*  using [[simp_trace_new mode=full]] *)
(*  using [[simp_trace_depth_limit=20]] *)
(*  using [[linarith_split_limit=12]] *)
proof(induction rule:elle_alt_sem.induct) 
case (1 t cp x e i cc net st st')
  then show ?case 
(* prelude copied from thing *)
    (* prelude:
- valid3'_qvalid
- qvalid_get_node1
- fact that instructions are always at least 1 byte
(ll_L_valid_bytes_length)
- program_list_of_lst_validate_head1
*)

(* lemma: build relationship
between program_sem and elle_instD *)
    apply(clarify)
    apply(simp only:Hoare.execution_continue)
    apply(case_tac fuel)
     apply(simp)
    apply(clarify)
    apply(frule_tac my_exec_continue)
    apply(simp del:elle_instD'.simps program_sem.simps)
    apply(case_tac "codegen'_check ((0, tend), ttree)", simp)
    apply(simp del:elle_instD'.simps program_sem.simps)
    apply(frule_tac valid3'_qvalid)
    apply(frule_tac qvalid_get_node1[rotated 1]) apply(auto simp del:elle_instD'.simps program_sem.simps)
    apply(frule_tac qvalid_cp_next_None1) apply(auto simp del:elle_instD'.simps program_sem.simps)
    print_state
    apply(frule_tac ll_L_valid_bytes_length) 
    apply(frule_tac qvalid_desc_bounded1) apply(auto simp del:elle_instD'.simps program_sem.simps)
    apply(case_tac " codegen'_check ((0, targend), ttree)", auto simp del:elle_instD'.simps program_sem.simps)
    apply(case_tac "program_list_of_lst_validate a", auto simp del:elle_instD'.simps program_sem.simps)
    apply(frule_tac cp = cp and a = "(0, targend)" and t = ttree in program_list_of_lst_validate_head1)
    (* OK, here we should use Hoare.execution_continue and the fact we just proved about inst_valid *)
        apply(safe)

        apply(auto simp del:elle_instD'.simps program_sem.simps)

    apply(rotate_tac -5) apply(drule_tac ll_valid_q.cases)
        apply(auto simp del:elle_instD'.simps program_sem.simps)

    print_state
     apply(frule_tac qvalid_codegen'_check1)
        apply(auto simp del:elle_instD'.simps program_sem.simps)

(* need lemma for permuting elle_stop and pc_update *)
(* i think this one isn't quite right though *)

    apply(frule_tac cc = "(clearprog' cc)"
and cc' = "(cc\<lparr>cctx_program := program.make (\<lambda>i. index aa (nat i)) (int (length aa))\<rparr>)"
and vcstart = "(vi\<lparr>vctx_pc := int 0\<rparr>)"
and vcstart' = "(vi\<lparr>vctx_pc := int ab\<rparr>)" (*targstart? *)
and irfinal = "st'"
and n = net
in elle_instD'_correct)         apply(auto simp del:elle_instD'.simps program_sem.simps)
    print_state
(* first, need a lemma saying that instD never looks at program counter *)

        apply(simp add:clearpc'_def del:elle_instD'.simps program_sem.simps)
       apply(simp add:clearprog'_def del:elle_instD'.simps program_sem.simps)
      apply(simp add:program.simps program.defs del:elle_instD'.simps program_sem.simps)
(* case_tac *)
      apply(simp add:program.simps program.defs clearpc'_def elle_stop.simps del:elle_instD'.simps program_sem.simps)
(* case split to see if we are already at I2E or we need
to actually run elle_stop*)
(* looks decent up until here *)
    print_state


(*      apply(simp only: program_sem.simps irmap.simps  program.simps)
    apply(unfold program_sem.simps) *)
(* old stuff follows *)
    apply(case_tac "program_sem (\<lambda>_. ()) (cc\<lparr>cctx_program := \<lparr>program_content = \<lambda>i. index aa (nat i), program_length = int (length aa)\<rparr>\<rparr>) (Suc 0) net
              (InstructionContinue (vi\<lparr>vctx_pc := int ab\<rparr>))")
      apply(drule_tac x = x1 in spec)

     apply(simp del:instruction_sem_def next_state_def)
    apply(case_tac "check_resources (vi\<lparr>vctx_pc := 0\<rparr>) (clearprog' cc) (vctx_stack vi)
             (aa ! ab) net")
    apply(case_tac " check_resources (x1\<lparr>vctx_pc := 0\<rparr>) (clearprog' cc) (vctx_stack x1)
            (Misc STOP) net")
       apply(simp del:instruction_sem_def next_state_def)
       apply(simp add:instruction_sem_def)
    print_state
       apply(case_tac nata, simp del:instruction_sem_def next_state_def)
       apply(simp del:instruction_sem_def next_state_def)
       apply(simp add:instruction_sem_def check_resources_def)

       apply(case_tac nata, simp del:instruction_sem_def next_state_def)
      apply(simp add:instruction_sem_def check_resources_def)
(* something different needed here *)
    print_state
      apply(clarsimp)
      apply(case_tac "int (length (vctx_stack x1)) \<le> 1024 \<and> 0 \<le> vctx_gas x1")
       apply(simp add:instruction_sem_def check_resources_def)
      apply(simp add:instruction_sem_def check_resources_def)
      apply(clarsimp)
    print_state
(* ok, this looks dope *)

    apply(case_tac "check_resources (vi\<lparr>vctx_pc := 0\<rparr>) (clearprog' cc) (vctx_stack vi)
             (aa ! ab) net")
    apply(case_tac " check_resources (x1\<lparr>vctx_pc := 0\<rparr>) (clearprog' cc) (vctx_stack x1)
            (Misc STOP) net")
       apply(simp del:instruction_sem_def next_state_def)
      apply(simp add:instruction_sem_def)
     apply(clarsimp)

(* final goal *)
    apply(case_tac " program_sem (\<lambda>_. ())
           (cc\<lparr>cctx_program :=
                 \<lparr>program_content = \<lambda>i. index aa (nat i),
                    program_length = int ab + int (length (inst_code (aa ! ab)))\<rparr>\<rparr>)
           (Suc 0) net (InstructionContinue (vi\<lparr>vctx_pc := int ab\<rparr>))")
       apply(simp del:instruction_sem_def next_state_def)
       apply(simp del:instruction_sem_def next_state_def)
    done
  next
  case (2 t cp x e i cc net cp' st st' st'')
  then show ?case
    
        apply(clarify)
    apply(simp only:Hoare.execution_continue)
    apply(case_tac fuel)
     apply(simp)
    apply(clarify)
    apply(frule_tac my_exec_continue)
    apply(simp del:elle_instD'.simps program_sem.simps)
    apply(case_tac "codegen'_check ((0, tend), ttree)", simp)
    apply(simp del:elle_instD'.simps program_sem.simps)
    apply(frule_tac valid3'_qvalid)
    apply(frule_tac qvalid_get_node1[rotated 1]) apply(auto simp del:elle_instD'.simps program_sem.simps)
    apply(frule_tac qvalid_cp_next_Some1) apply(auto simp del:elle_instD'.simps program_sem.simps)
    print_state
    apply(frule_tac ll_L_valid_bytes_length) 
    apply(frule_tac qvalid_desc_bounded1) apply(auto simp del:elle_instD'.simps program_sem.simps)
    apply(case_tac "program_list_of_lst_validate a")
    apply(simp del:elle_instD'.simps program_sem.simps)
    apply(simp del:elle_instD'.simps program_sem.simps)

    apply(case_tac " codegen'_check ((0, tend), ttree)", auto simp del:elle_instD'.simps program_sem.simps)
    apply(case_tac "program_list_of_lst_validate a", auto simp del:elle_instD'.simps program_sem.simps)
    apply(frule_tac cp = cp and a = "(0, tend)" and t = ttree in program_list_of_lst_validate_head1)
    (* OK, here we should use Hoare.execution_continue and the fact we just proved about inst_valid *)
        apply(safe)

        apply(auto simp del:elle_instD'.simps program_sem.simps)

    apply(rotate_tac -7) apply(drule_tac ll_valid_q.cases)
        apply(auto simp del:elle_instD'.simps program_sem.simps)

    print_state
     apply(frule_tac qvalid_codegen'_check1)
        apply(auto simp del:elle_instD'.simps program_sem.simps)

(* need lemma for permuting elle_stop and pc_update *)
(* i think this one isn't quite right though *)

    apply(frule_tac cc = "(setprog' cc bogus_prog)"
and cc' = "(cc\<lparr>cctx_program := program.make (\<lambda>i. index aa (nat i)) (int (length aa))\<rparr>)"
and vcstart = "(vi\<lparr>vctx_pc := int 0\<rparr>)"
and vcstart' = "(vi\<lparr>vctx_pc := int ab\<rparr>)" (*targstart? *)
and irfinal = "st'"
and n = net
in elle_instD'_correct) 
        apply(auto simp del:elle_instD'.simps program_sem.simps)
    print_state
        apply(simp_all add:clearpc'_def clearprog'_def setprog'_def del:elle_instD'.simps program_sem.simps)
     apply(simp add:program.simps program.defs del:elle_instD'.simps program_sem.simps)
     apply(case_tac " inst_code (aa ! ab)")
      apply(simp) apply(simp)

    (*1 goal. things seem ok up until here *)
    apply(simp add:program.simps program.defs del:elle_instD'.simps program_sem.simps)
    apply(case_tac "elle_instD' (aa ! ab) (cc\<lparr>cctx_program := bogus_prog\<rparr>) net
              (InstructionContinue (vi\<lparr>vctx_pc := 0\<rparr>))")
      apply(drule_tac x = x1 in spec)
     apply(simp del:instruction_sem_def next_state_def)
     apply(case_tac "check_resources (vi\<lparr>vctx_pc := 0\<rparr>) (cc\<lparr>cctx_program := bogus_prog\<rparr>) (vctx_stack vi) (aa ! ab) net")
     apply(simp del:instruction_sem_def next_state_def)
    apply(case_tac "next_state (\<lambda>_. ()) (cc\<lparr>cctx_program := \<lparr>program_content = \<lambda>i. index aa (nat i), program_length = int (length aa)\<rparr>\<rparr>) net
           (InstructionContinue (vi\<lparr>vctx_pc := int ab\<rparr>))")
       apply(case_tac "index aa ab")
        apply(auto simp del:instruction_sem_def next_state_def) (* was auto *)
    print_state
    apply(case_tac " check_resources (vi\<lparr>vctx_pc := int ab\<rparr>) (cc\<lparr>cctx_program := \<lparr>program_content = \<lambda>i. index aa (nat i), program_length = int (length aa)\<rparr>\<rparr>)
            (vctx_stack vi) (Misc STOP) net")
       apply(simp)
    apply(simp)


    apply(case_tac "check_resources (vi\<lparr>vctx_pc := int ab\<rparr>)
            (cc\<lparr>cctx_program :=
                  \<lparr>program_content = \<lambda>i. index aa (nat i), program_length = int (length aa)\<rparr>\<rparr>)
            (vctx_stack vi) (aa ! ab) net")
      apply(drule_tac x = act in spec)
    apply(drule_tac x = vc in spec)
      apply(drule_tac x = venv in spec)
      apply(auto)
    print_state
      apply(drule_tac x = nata in spec)
      apply(case_tac x1) apply(case_tac x1a)
    apply(clarify)
      apply(simp)
    print_state


(* final goal *)
(* under construction  *)
(* need case_tac nata? *)
     apply(case_tac "index aa ab")
     apply(clarsimp del:instruction_sem_def next_state_def)
     apply(case_tac "inst_code (aa ! ab)", auto)

    apply(case_tac " check_resources (vi\<lparr>vctx_pc := int ab\<rparr>) (cc\<lparr>cctx_program := \<lparr>program_content = \<lambda>i. index aa (nat i), program_length = int (length aa)\<rparr>\<rparr>)
             (vctx_stack vi) (aa ! ab) net")
    apply(simp only:)
     apply(simp del:instruction_sem_def next_state_def check_resources_def)

     apply(case_tac "check_resources (vi\<lparr>vctx_pc := 0\<rparr>) (cc\<lparr>cctx_program := bogus_prog\<rparr>) (vctx_stack vi) (aa ! ab) net")
    apply(simp only:)
      apply(simp del:instruction_sem_def next_state_def check_resources_def)

    apply(case_tac nata)
       apply(simp del:instruction_sem_def next_state_def check_resources_def)

    apply(frule_tac elle_alt_sem_halted)
      apply(simp del:instruction_sem_def next_state_def check_resources_def)

    apply(frule_tac elle_alt_sem_halted)
      apply(simp del:instruction_sem_def next_state_def check_resources_def)
      apply(clarify)

      apply(simp del:instruction_sem_def check_resources_def)

(* next_state_halted?
need to show that b/c we start in
a ToEnvironment state,
that same state is returned in the end *)

    apply(case_tac "
 instruction_sem (vi\<lparr>vctx_pc := int ab\<rparr>)
               (cc\<lparr>cctx_program :=
                     \<lparr>program_content = \<lambda>i. index aa (nat i), program_length = int (length aa)\<rparr>\<rparr>)
               (aa ! ab) net
")
      apply(simp del:instruction_sem_def check_resources_def)
      apply(simp del:instruction_sem_def check_resources_def)

    apply(simp only:)

     apply(frule_tac elle_alt_sem_halted)
     apply(simp only: split:if_splits, clarify)

(* need a lemma about check_resources
if two cctx differ only in programs

 *)
      apply(frule_tac
  v' = "(vi\<lparr>vctx_pc := 0\<rparr>)" and
  c' =  "(cc\<lparr>cctx_program := bogus_prog\<rparr>)" and
  pc' = 0 and
  prog' = bogus_prog in
 check_resources_gen) apply(clarify)
        apply(simp del:instruction_sem_def check_resources_def)
       apply(simp del:instruction_sem_def check_resources_def)
      apply(clarify)

      apply(frule_tac
  v' = "(vi\<lparr>vctx_pc := 0\<rparr>)" and
  c' =  "(cc\<lparr>cctx_program := bogus_prog\<rparr>)" and
  pc' = 0 and
  prog' = bogus_prog in
 check_resources_gen) apply(clarify)
        apply(simp del:instruction_sem_def check_resources_def)
       apply(simp del:instruction_sem_def check_resources_def)
      apply(clarify)

    apply(case_tac " check_resources (vi\<lparr>vctx_pc := 0\<rparr>) (cc\<lparr>cctx_program := bogus_prog\<rparr>)
            (vctx_stack vi) (aa ! ab) net") 
           apply(frule_tac
  v' = "(vi\<lparr>vctx_pc := ab\<rparr>)" and
  c' =  "(cc\<lparr>cctx_program :=
              \<lparr>program_content = \<lambda>i. index aa (nat i),
                 program_length = int (length aa )\<rparr>\<rparr>)" and
  pc' = ab and
  prog' = "\<lparr>program_content = \<lambda>i. index aa (nat i),
                 program_length = int (length aa )\<rparr>" in
 check_resources_gen) apply(clarify)
       apply(simp (no_asm_simp))
      apply(simp (no_asm_simp))
     apply(clarify)
    apply(rotate_tac -2)
    print_simpset
        apply(simp only: HOL.if_not_P HOL.if_False)
    apply(case_tac nata) apply(clarify)
    apply(simp only:program_sem.simps)
        apply(simp del:instruction_sem_def meter_gas_def inst_stack_numbers.simps check_resources_def)
     apply(clarify)
    apply(drule_tac spec)
     apply(clarify)
       apply(simp (no_asm_simp))

apply(clarify)
    apply(simp only:program_sem.simps)
        apply(simp del:instruction_sem_def meter_gas_def inst_stack_numbers.simps check_resources_def)

     apply(clarify)
    apply(drule_tac spec)
     apply(clarify)
    apply(simp (no_asm_simp))
    done

next
  case (3 t cp x e d cc net st st')
  then show ?case 

(* original proof follows, i am now condensing some goals *)
    apply(clarify)
    apply(case_tac fuel, clarify) apply(simp)

    apply(frule_tac valid3'_qvalid) apply(simp)
    apply(simp split:option.split_asm)
     apply(frule_tac cp = cp and a = "(0, tend)" and t = ttree in program_list_of_lst_validate_head1) apply(auto)
         apply(drule_tac qvalid_get_node1[rotated 1]) apply(simp)
    apply(rotate_tac -1)
      apply(frule_tac ll_valid_q.cases, auto)

         apply(frule_tac qvalid_desc_bounded1) apply(simp) apply(simp)
    apply(frule_tac qvalid_codegen'_check1, simp) apply(simp) apply(simp)
     apply(simp add:program.defs) apply(auto)
         apply(drule_tac qvalid_get_node1[rotated 1]) apply(simp)
     apply(rotate_tac -1) apply(frule_tac ll_valid_q.cases, auto)

(* heck yes *)
    apply(simp add:clearpc'_def )
(*    apply(case_tac "check_resources (vi\<lparr>vctx_pc := 0\<rparr>) (clearprog' cc) (vctx_stack vi)
            (Pc JUMPDEST) net") apply(clarsimp) *)
    apply(simp add:check_resources_def)
(*
    apply(simp add:elle_stop_def)
        apply(simp add:program.defs clearprog'_def elle_stop_def check_resources_def)
*)
    apply(subgoal_tac "x2a = Pc JUMPDEST")
    apply(clarsimp)
     apply(auto) (* was just auto 3 3 *)
(* now we need the fact about the length running out *)
      apply(simp add:program.defs clearprog'_def check_resources_def)
(* we will prove this subgoal later with "head" theorem,
can delete hypotheses to make computation faster if we need *)
       apply(clarsimp)
       apply(frule_tac qvalid_codegen'_check1, auto)
       apply(case_tac nata, auto)
    apply(split option.split_asm)
    apply(split option.split_asm) 
         apply(auto)
    apply(split option.split_asm) 
        apply(auto)
      apply(simp add:program.defs clearprog'_def check_resources_def)
       apply(simp add:program.defs clearprog'_def check_resources_def)
       apply(frule_tac qvalid_cp_next_None1, auto)
       apply(frule_tac qvalid_get_node1, auto) apply(rotate_tac -1)
       apply(drule_tac ll_valid_q.cases, auto)

      apply(case_tac nata, auto)
      apply(split option.split_asm) apply(auto)
       apply(split option.split_asm) apply(auto)
       apply(split option.split_asm) apply(auto)
        apply(split option.split_asm) apply(auto)
       apply(split option.split_asm) apply(auto)
      apply(split option.split_asm) apply(auto)
       apply(split option.split_asm) apply(auto)
      apply(simp add:program.defs clearprog'_def check_resources_def)
    apply(auto)
      apply(simp add:program.defs clearprog'_def check_resources_def)
      apply(simp add:program.defs clearprog'_def check_resources_def)

      apply(auto)
       apply(frule_tac qvalid_codegen'_check1, auto)
       apply(frule_tac qvalid_cp_next_None1, auto)
       apply(frule_tac qvalid_get_node1, auto) apply(rotate_tac -1)
       apply(drule_tac ll_valid_q.cases, auto)

      apply(case_tac nata, auto)
      apply(split option.split_asm) apply(auto)
       apply(split option.split_asm) apply(auto)
       apply(split option.split_asm) apply(auto)
        apply(split option.split_asm) apply(auto)
       apply(split option.split_asm) apply(auto)
      apply(split option.split_asm) apply(auto)
       apply(split option.split_asm) apply(auto)
      apply(simp add:program.defs clearprog'_def check_resources_def)
      apply(simp add:program.defs clearprog'_def check_resources_def)
     apply(simp add:program.defs clearprog'_def check_resources_def)

    apply(auto)

       apply(frule_tac qvalid_codegen'_check1, auto)
       apply(frule_tac qvalid_cp_next_None1, auto)
     apply(frule_tac qvalid_get_node1, auto)
     apply(rotate_tac -1)
     apply(drule_tac ll_valid_q.cases, auto)

    apply(frule_tac program_list_of_lst_validate_head1, auto)
     apply(frule_tac qvalid_get_node1, auto)
     apply(rotate_tac -1)
     apply(drule_tac ll_valid_q.cases, auto)
    apply(simp add:program.defs)
    done
next
  case (4 st'' t cp x e d cp' cc net st st')
  then show ?case
(* copied over from previous case, some of these initial tactics may be wrong *)

(* let's do an outline of this proof:
- the "targstart"'th child of the output is a Label
  - This is because root valid3 \<rightarrow> root qvalid \<rightarrow> descendent qvalid
  - Plus the "bounded" and "output_validate_correct"
- with this we can prove that the next instruction to evaluate will be a label
  - at that point, we need to _not_ crunch through another iteration of fuel parameter
  - instead we need to combine our assumptions
    - in particular, use the cp_next_Some1 lemma to prove that starting PC corresponds to the next node (?)
*)

        apply(clarify)
    apply(case_tac fuel, clarify) apply(simp)

(* need to be careful about where exactly we are doing reasoning with qvalid
so that we can minimize the size of these scripts *)
    apply(frule_tac valid3'_qvalid) apply(simp) apply(clarify)
         apply(frule_tac qvalid_get_node1[rotated 1]) apply(simp)
    apply(rotate_tac -1)
    apply(frule_tac ll_valid_q.cases, auto)
    apply(case_tac "codegen'_check ((0, tend), ttree)", auto)
    apply(case_tac " program_list_of_lst_validate aa", auto)
    apply(frule_tac a = "(0, tend)" and adl = a in program_list_of_lst_validate_head1, auto) 

    apply(simp split:option.split_asm) apply(auto)
         apply(frule_tac qvalid_desc_bounded1) apply(simp) apply(simp)
    apply(frule_tac qvalid_codegen'_check1, simp) apply(simp) apply(simp)
     apply(simp add:program.defs) 

    apply(frule_tac qvalid_cp_next_Some1, auto)
    apply(simp add:program.defs clearprog'_def check_resources_def)
    apply(auto)
    apply(case_tac "ab ! a", auto)


    apply(case_tac " clearpc' (InstructionContinue vi)", auto)
    apply(simp add:program.defs clearprog'_def check_resources_def)

     apply(case_tac "int (length (vctx_stack x1)) \<le> 1024 \<and> 1 \<le> vctx_gas x1", auto)
       apply(simp add:program.defs clearprog'_def check_resources_def clearpc'_def)
    apply(case_tac "ab ! a", auto)
       apply(simp add:program.defs clearprog'_def check_resources_def clearpc'_def)
       apply(drule_tac x = act in spec) apply(drule_tac x = vc in spec) apply(drule_tac x = venv in spec, auto)
    apply(subgoal_tac 
"vi\<lparr>vctx_pc := int a + 1, vctx_gas := vctx_gas vi - 1\<rparr> =
(vi\<lparr>vctx_gas := vctx_gas vi - 1, vctx_pc := 1 + int a\<rparr>)")
        apply(auto)

       apply(simp add:program.defs clearprog'_def check_resources_def clearpc'_def)
      apply(case_tac "int (length (vctx_stack vi)) \<le> 1024 \<and> 1 \<le> vctx_gas vi", auto)
      apply(case_tac "int (length (vctx_stack vi)) \<le> 1024 \<and> 1 \<le> vctx_gas vi", auto)

     apply(frule_tac elle_alt_sem_halted) 
    apply(case_tac vi) apply(case_tac x1)
     apply(auto simp add:clearpc'_def)
(*
          apply(auto)

       apply(simp add:program.defs clearprog'_def check_resources_def clearpc'_def)
    apply(case_tac " int (length (vctx_stack vi)) \<le> 1024", auto)
       apply(frule_tac elle_alt_sem_halted) apply(auto)
       apply(frule_tac elle_alt_sem_halted) apply(auto)

             apply(simp add:program.defs clearprog'_def check_resources_def clearpc'_def)
*)
    done
next
  case (5 t cpre cj xj ej dj nj cl cc net st st' st'')
  then show ?case
    apply(auto)
    apply(simp add:clearpc'_def)
     apply(split option.split_asm, auto)
     apply(split option.split_asm, auto)
     apply(case_tac fuel, auto)
     apply(split option.split_asm, auto)
     (*apply(split option.split_asm, auto)*) (* this is probably splitting the wrong thing *)

     
     apply(case_tac t, auto)


(* ensure these are applying to the correct descends fact
i.e., the JUMP
*)
(* we need to apply some additional lemma here (but what exactly?) *)
    apply(case_tac "codegen'_check ((0, tend), ttree)", simp)
    apply(simp del:elle_instD'.simps program_sem.simps)
    apply(frule_tac valid3'_qvalid)
    apply(frule_tac cp = "ej @ dj" in qvalid_get_node1[rotated 1]) apply(auto simp del:elle_instD'.simps program_sem.simps)
    print_state
(*   apply(rotate_tac 2) *)
     apply(frule_tac cp = "ej @ dj" in qvalid_desc_bounded1[rotated 1]) apply(auto simp del:elle_instD'.simps program_sem.simps)

      apply(frule_tac program_list_of_lst_validate_jmp1)
         apply(auto simp del:elle_instD'.simps program_sem.simps)

       apply(case_tac ild2, auto)
       apply(case_tac "length (output_address cl) = net", auto)
       apply(case_tac "output_address cl = []", auto)
    apply(case_tac "32 < length (output_address cl) ", auto)

    apply(case_tac " program_content (program.make (\<lambda>i. index x2a (nat i)) (int (length x2a))) (int targstart)")
     apply(auto simp add:program.defs)

    apply(rotate_tac 18)
    apply(frule_tac ll_valid_q.cases, auto)

    print_state

    apply(simp add:check_resources_def)
    apply(case_tac "x2a ! aa", auto)

       apply(case_tac "int (length (vctx_stack vi)) \<le> 1023 \<and> 3 \<le> vctx_gas vi", auto)

    apply(case_tac "program_content (program.make (\<lambda>i. index x2a (nat i)) (int (length x2a))) (int aa)")
     apply(auto simp add:program.defs)

    apply(case_tac nata, auto)
    apply(simp add:check_resources_def)

      apply(case_tac "vctx_gas vi < 11")
       apply(auto simp del:elle_instD'.simps program_sem.simps)
     apply(frule_tac elle_alt_sem_halted) apply(auto)
       apply(case_tac "int (length (vctx_stack vi)) \<le> 1023 \<and> 3 \<le> vctx_gas vi", auto)

       apply(case_tac nata, auto)
        apply(auto simp add:Int.nat_add_distrib)

    apply(case_tac " index x2a (nat (uint (word_of_int (foldl (\<lambda>u. bin_cat u 8) 0 (map uint (output_address cl))) :: 256 word)))")
    apply(auto)
    print_state
(* need a  lemma relating the address to the result on the stack *)
    apply(simp add:word_of_int_def)
    apply(simp add:Abs_word_inverse)
apply(cut_tac cl = cl in "reconstruct_address_gen2")
    apply(simp add: sym[OF Bit_Representation.bintrunc_mod2p])
(* descend_eq_lr2, but we need to do a case split on ej @ st first *)
     apply(case_tac "ej @ dj", clarify) apply(simp)
    apply(simp)
    apply(frule_tac kh = ab in ll_descend_eq_l2r)
    apply(frule_tac validate_jump_targets_spec)
     apply(simp)
(* case split on whether cl > 2 ^ 256.
if it is greater, then we can derive a contradiction from the fact that 
PUSH_N (output_address cl) is in x2a
and that x2a passed through program_list_of_lst_validate
(need an auxiliary result about how if PUSH_N is in a result of
program_list_of_lst_validate, then the PUSH_N argument has 1-32 bytes
)
(then, need a lemma about how if we have a bytestream of 1-32 bytes,
bincat'ing them will yield a number less than 2^256)

otherwise, we know cl mod 2 ^ 256 = cl
so we can proceed with the theorem and use the fact that JUMPDEST
is at cl.
*)

(* *** Here is where the branching gets going *** *)
    apply(simp) apply(safe)
(* we need a fact about label/inst *)
(* something weird is happening here.
i think we need uniqueness of labels, which comes from
valid3' of the root *)

(*
another thought.
perhaps what we actually need is
to use list_of_lst_validate_head' on the label,
so we can prove that the lookup results in a PC Jumpdest
*)

(* we have a fact about "!" here, but we may need an additional
fact about index being less than length *)
(* know aa < length x2a
we know this b/c of one of our desc_bounded lemmas
*)

(* here we need to put together
- reconstruct_address_gen2
- output_address_length_bound
- "a < b \<longrightarrow> a mod b = a"
- at that point we will be
"looking up" the value we want
*)
    print_state
     apply(simp add:ll_valid3'_def)
(* *** first use of valid3'_cases - should be the only one, I think *** *)
     apply(drule_tac "ll_valid3'p.cases")
           apply(simp_all)
    print_state

(* *** still 2 goals here, good *** *)
     apply(clarsimp)
    apply(subgoal_tac "ej = []")
      apply(auto simp only:)
      apply(simp_all)
    apply(rotate_tac -2)
    apply(drule_tac x = st in spec)
      apply(auto simp only:)

(* relabel, then l2r *)
       apply(case_tac st, simp) apply(simp)
    apply(frule_tac q = "(0, length x2a)" and e = e in ll_descend_eq_l2r_list)
    print_state
    apply(simp add:ll3'_descend_def)

(* *** looks OK here *** *)

    apply(subgoal_tac "nat (foldl (\<lambda>u. bin_cat u 8) 0 (map uint (output_address cl)) mod 115792089237316195423570985008687907853269984665640564039457584007913129639936) = cl")
       apply(clarsimp)
    print_state

       apply(frule_tac a = "(0, length x2a)" and cp = st
             and adl = cl in program_list_of_lst_validate_head1)
           apply(rule_tac ll_descend_eq_r2l)
    apply(simp)
    
    print_state
          defer (* fact about label, easy *)
    print_state
          apply(simp_all)
        apply(clarsimp)

        apply(drule_tac x = act in spec)
        apply(rotate_tac -1)
    apply(drule_tac x = vc in spec)
        apply(rotate_tac -1)
    apply(drule_tac x = venv in spec)
        apply(clarsimp)
    apply(rotate_tac -1)
        apply(drule_tac x = nata in spec)
                                                
(* *** OK. we are basically done here.
we just need to sort out the relationship between
- cl
- roundtrip ser/deser of cl
- a
these should all be equal, question is what is the easiest way to prove it.
*** *)
(* *** use reconstruct_address_gen2_int ? *** *)
    apply(subgoal_tac "cl = a")
         apply(clarsimp)
    apply(subgoal_tac
"uint
                 (word_of_int
                   (foldl (\<lambda>u. bin_cat u 8) 0 (map uint (output_address cl))) :: 256 word)
 = int cl")
    apply(case_tac vi)
          apply(clarsimp)
         apply(simp add:Word.int_word_uint)

(* determinism *) defer

        apply(subgoal_tac "cl < 2^256")
         apply(simp add: Word_Miscellaneous.nat_mod_eq')
        apply(simp)
        apply(subgoal_tac "length (output_address cl) \<le> 32")
        apply(cut_tac cl = cl in output_address_length_bound)
         apply(simp)
         apply(case_tac "length (output_address cl) = 32")
          apply(simp)
    apply(subgoal_tac
"256 ^ (length (output_address cl) :: nat) <
 (256 ^ 32 :: nat)")
    apply(simp)
    apply(rule_tac  Power.linordered_semidom_class.power_strict_increasing)
          apply(simp (no_asm_simp)) 
    apply(simp (no_asm_simp)) 
    apply(simp (no_asm_simp)) 

(* done with gross math part *)
       apply(case_tac dj)
apply(simp del: elle_instD'.simps program_sem.simps)
    apply(simp del: elle_instD'.simps program_sem.simps)
       apply(case_tac ej)
apply(simp (no_asm_simp) del: elle_instD'.simps program_sem.simps)
       apply(simp del: elle_instD'.simps program_sem.simps)
    apply(clarify)
       apply(simp (no_asm_use))

(* next big case *)
    defer

(* this case (previously defered:
- root is valid
- descendent is valid
- thus cl < ba because of LLab *)

      apply(drule_tac k = st in ll_descend_eq_r2l)
      apply(drule_tac t = "llt.LSeq st l"
                  and ad = "(cl, ba)"
                  and d = "llt.LLab el idxl"  in qvalid_get_node1)
    apply(simp)
      apply(simp)
    apply(rotate_tac -1)
    apply(drule_tac qvalid_llab) apply(simp)

(* this case is because of determinism of
descends/ll_get_node - probably can use
descend_eq_r2l *)
      apply(drule_tac k = st in ll_descend_eq_r2l)
    apply(simp)

(* *** current point  *** *)

(* copied in *)

    apply(subgoal_tac "nat (foldl (\<lambda>u. bin_cat u 8) 0 (map uint (output_address cl)) mod 115792089237316195423570985008687907853269984665640564039457584007913129639936) = cl")
       apply(clarsimp)
    print_state

    apply(subgoal_tac "cl = a")
         apply(clarsimp)


       apply(frule_tac a = "(0, length x2a)" and cp = "ej @ st"
             and adl = cl in program_list_of_lst_validate_head1)
    apply(simp)

         defer 
    apply(simp)
    apply(simp)

       apply(clarsimp)
       apply(drule_tac x = act in spec) apply(rotate_tac -1)
    apply(drule_tac x = vc in spec) apply(rotate_tac -1)
       apply(drule_tac x = venv in spec) apply(rotate_tac -1)
       apply(clarsimp) apply(rotate_tac -1)
    apply(drule_tac x = nata in spec) 

    apply(subgoal_tac
"uint
                 (word_of_int
                   (foldl (\<lambda>u. bin_cat u 8) 0 (map uint (output_address cl))) :: 256 word)
 = int cl")
    apply(case_tac vi)
          apply(clarsimp)
         apply(simp add:Word.int_word_uint)

(* *** should be smooth sailing from here :D *** *)

(* for this first case, need to stitch back together the ej @ st path
then use determinism
*)

(* need valid3_desc fact to get down
to the lower sequence we actually care about *)
(* r2l
splitpath *)


(* this is applying to the wrong fact *)
    apply(subgoal_tac
"
(((0, length x2a), ttree),
 ((a, b), llt.LLab cpre cj),
ej @ st)
\<in> ll3'_descend
"
)
       apply(frule_tac k = ej in ll3_descend_nonnil)
       apply(rotate_tac -2)
       apply(drule_tac ll3_descend_splitpath)
       apply(clarsimp)
    apply(case_tac st)
        apply(simp)
       apply(clarsimp)

(* next, determinism *)

    apply(drule_tac k = "hd#tl" in ll_descend_eq_r2l)
apply(drule_tac k = "hd#tl" in ll_descend_eq_r2l)
       apply(clarsimp)


(* then apply valid3'_desc_full *)
       apply(rotate_tac -1)
       apply(drule_tac "ll_descend_eq_l2r")
    apply(rotate_tac -1)
       apply(frule_tac ll_valid3'_desc_full)
        apply(simp)
    apply(frule_tac k = ed in ll3_descend_nonnil)
       apply(clarsimp)
       apply(rotate_tac -1)
       apply(drule_tac ll_valid3'.cases)
             apply(simp_all)
       apply(clarsimp) apply(rotate_tac -1)
    apply(drule_tac x = "ab#list" in spec)
       apply(clarsimp)
       apply(safe)

(* "does-not-exist" case *)
        apply(clarsimp)
        apply(rotate_tac -1)
        apply(drule_tac x = a in spec) apply(rotate_tac -1)
    apply(drule_tac x = b in spec) apply(rotate_tac -1)
        apply(drule_tac x = cpre in spec) apply(rotate_tac -1)
    apply(drule_tac k = "ab#list" in ll_descend_eq_r2l)
        apply(clarsimp)
        apply(simp add:ll_descend_eq_l2r)

(* exists-case *)
       apply(drule_tac k = "ab#list" in ll_descend_eq_r2l)
       apply(drule_tac k = "ab#list" in ll_descend_eq_r2l)
       apply(clarsimp)

(* deferred goals *)
      apply(case_tac "ej@st")
       apply(clarsimp)
      apply(clarsimp)
      apply(rule_tac ll_descend_eq_l2r)
      apply(clarsimp)
                                 
(* gross math (tm) goal *)     
        apply(subgoal_tac "cl < 2^256")
         apply(simp add: Word_Miscellaneous.nat_mod_eq')
        apply(simp)
        apply(subgoal_tac "length (output_address cl) \<le> 32")
        apply(cut_tac cl = cl in output_address_length_bound)
         apply(simp)
         apply(case_tac "length (output_address cl) = 32")
          apply(simp)
    apply(subgoal_tac
"256 ^ (length (output_address cl) :: nat) <
 (256 ^ 32 :: nat)")
    apply(simp)
    apply(rule_tac  Power.linordered_semidom_class.power_strict_increasing)
          apply(simp (no_asm_simp)) 
    apply(simp (no_asm_simp)) 
    apply(simp (no_asm_simp)) 

      apply(drule_tac t = "ttree"
                  and ad = "(cl, b)"
                  and d = "llt.LLab cpre cj"  in qvalid_get_node1)
    apply(simp)
    apply(rotate_tac -1)
    apply(drule_tac qvalid_llab) apply(simp)
    done
next
(* similar to case 5 *)
  case (6 t cpre cj xj ej dj nj cl cc net st st' st'')
  then show ?case
  apply(auto)
      apply(simp add:clearpc'_def)
       apply(split option.split_asm, auto)
     apply(split option.split_asm, auto)
     apply(case_tac fuel, auto)
     apply(split option.split_asm, auto)
     apply(case_tac t, auto)
(*     apply(case_tac cc, auto) *)
apply(frule_tac valid3'_qvalid)
    apply(frule_tac cp = "ej @ dj" in qvalid_get_node1[rotated 1]) apply(auto simp del:elle_instD'.simps program_sem.simps)
     apply(frule_tac cp = "ej @ dj" in qvalid_desc_bounded1[rotated 1]) apply(auto simp del:elle_instD'.simps program_sem.simps)

      apply(frule_tac program_list_of_lst_validate_jmpi1)
         apply(auto simp del:elle_instD'.simps program_sem.simps)

         (* *** current point. *** *)
       apply(case_tac ild2, auto)
       apply(case_tac "length (output_address cl) = net", auto)
       apply(case_tac "output_address cl = []", auto)
    apply(case_tac "32 < length (output_address cl) ", auto)

    (* need targstart < lenth x2a *)
    apply(case_tac " program_content (program.make (\<lambda>i. index x2a (nat i)) (int (length x2a))) (int targstart)")
    apply(auto simp add:program.defs)

    apply(rotate_tac 18)
        apply(frule_tac ll_valid_q.cases, auto)

            apply(simp add:check_resources_def)
            apply(case_tac "x2a ! aa", auto)


                   apply(case_tac "int (length (vctx_stack vi)) \<le> 1023 \<and> 3 \<le> vctx_gas vi", auto)
    apply(case_tac "program_content (program.make (\<lambda>i. index x2a (nat i)) (int (length x2a))) (int aa)")
    apply(auto simp add:program.defs)

        apply(case_tac nata, auto)
    apply(simp add:check_resources_def)

      apply(case_tac "vctx_gas vi < 13")
      apply(auto simp del:elle_instD'.simps program_sem.simps)

      (* *** starting to diverge from case 5... *** *)
      
      apply(case_tac " vctx_stack vi", auto)
      apply(simp add: Evm.strict_if_def)
      apply(case_tac "ab = 0", auto)

      apply(subgoal_tac "(x2a ! nat (int aa + (1 + int (length (output_address cl))))) = Pc JUMPI")
      apply(clarsimp)
      
    apply(case_tac " index x2a (nat (uint (word_of_int (foldl (\<lambda>u. bin_cat u 8) 0 (map uint (output_address cl))) :: 256 word)))")
    apply(auto)

     apply(case_tac "ej @ dj", clarify) apply(simp)
    apply(simp)
    apply(frule_tac kh = ac in ll_descend_eq_l2r)
    apply(frule_tac validate_jump_targets_spec_jumpi)
     apply(simp)

     (* *** Here is where the branching gets going *** *)
    apply(simp) apply(safe)
         apply(simp add:ll_valid3'_def)
(* *** first use of valid3'_cases - should be the only one, I think *** *)
     apply(drule_tac "ll_valid3'p.cases")
           apply(simp_all)
    print_state

     apply(clarsimp)
    apply(subgoal_tac "ej = []")
      apply(auto simp only:)
      apply(simp_all)
    apply(rotate_tac -2)
    apply(drule_tac x = st in spec)
    apply(auto simp only:)

           apply(case_tac st, simp) apply(simp)
    apply(frule_tac q = "(0, length x2a)" and e = e in ll_descend_eq_l2r_list)
    print_state
    apply(simp add:ll3'_descend_def)

        apply(simp add:word_of_int_def)
        apply(simp add:Abs_word_inverse)
            apply(cut_tac cl = cl in "reconstruct_address_gen2")
    apply(simp add: sym[OF Bit_Representation.bintrunc_mod2p])
    apply(subgoal_tac "nat (foldl (\<lambda>u. bin_cat u 8) 0 (map uint (output_address cl)) mod 115792089237316195423570985008687907853269984665640564039457584007913129639936) = cl")
    apply(clarsimp)


           apply(frule_tac a = "(0, length x2a)" and cp = st
             and adl = cl in program_list_of_lst_validate_head1)
           apply(rule_tac ll_descend_eq_r2l)
               apply(simp)

               defer (* fact about label *)

         apply(simp_all)
         apply(clarsimp)    

                 apply(drule_tac x = act in spec)
        apply(rotate_tac -1)
    apply(drule_tac x = vc in spec)
        apply(rotate_tac -1)
    apply(drule_tac x = venv in spec)
        apply(clarsimp)
    apply(rotate_tac -1)
        apply(drule_tac x = nata in spec)


            apply(subgoal_tac "cl = a")
         apply(clarsimp)
    apply(subgoal_tac
"uint
                 (word_of_int
                   (foldl (\<lambda>u. bin_cat u 8) 0 (map uint (output_address cl))) :: 256 word)
 = int cl")
    apply(case_tac vi)
          apply(clarsimp)
          apply(simp add:Word.int_word_uint)

          defer (* descends determinism *)

          (*
        apply(subgoal_tac "length (output_address cl) \<le> 32")
        apply(cut_tac cl = cl in output_address_length_bound)
         apply(simp)
         apply(case_tac "length (output_address cl) = 32")
          apply(simp)
*)
          
        apply(subgoal_tac "cl < 2^256")
         apply(simp add: Word_Miscellaneous.nat_mod_eq')
        apply(simp)
        apply(subgoal_tac "length (output_address cl) \<le> 32")
        apply(cut_tac cl = cl in output_address_length_bound)
         apply(simp)
         apply(case_tac "length (output_address cl) = 32")
          apply(simp)
    apply(subgoal_tac
"256 ^ (length (output_address cl) :: nat) <
 (256 ^ 32 :: nat)")
    apply(simp)
    apply(rule_tac  Power.linordered_semidom_class.power_strict_increasing)
          apply(simp (no_asm_simp)) 
    apply(simp (no_asm_simp)) 
    apply(simp (no_asm_simp)) 

    (* done with gross math/mod reasoning *)
                 apply(case_tac dj)
apply(simp del: elle_instD'.simps program_sem.simps)
    apply(simp del: elle_instD'.simps program_sem.simps)
       apply(case_tac ej)
apply(simp (no_asm_simp) del: elle_instD'.simps program_sem.simps)
       apply(simp del: elle_instD'.simps program_sem.simps)
    apply(clarify)
       apply(simp (no_asm_use))


       (* next big case *) defer
       
       print_state

       apply(subgoal_tac
         "nat (int aa + (1 + int (length (output_address cl))))
=
Suc (aa + length (output_address cl))")
       apply(simp)
       apply(simp add:Int.nat_int_add)

       (* previously deferred case - cl < ba because of valid LLab node *)
             apply(drule_tac k = st in ll_descend_eq_r2l)
      apply(drule_tac t = "llt.LSeq st l"
                  and ad = "(cl, ba)"
                  and d = "llt.LLab el idxl"  in qvalid_get_node1)
    apply(simp)
      apply(simp)
    apply(rotate_tac -1)
    apply(drule_tac qvalid_llab) apply(simp)

    (* determinism *)
          apply(drule_tac k = st in ll_descend_eq_r2l)
    apply(simp)

(* final case *)

    apply(subgoal_tac "cl = a")
    apply(clarsimp)

           apply(frule_tac a = "(0, length x2a)" and cp = "ej @ st"
             and adl = cl in program_list_of_lst_validate_head1)
    apply(simp)

    defer

        apply(simp)
        apply(simp)

               apply(clarsimp)
       apply(drule_tac x = act in spec) apply(rotate_tac -1)
    apply(drule_tac x = vc in spec) apply(rotate_tac -1)
       apply(drule_tac x = venv in spec) apply(rotate_tac -1)
       apply(clarsimp) apply(rotate_tac -1)
       apply(drule_tac x = nata in spec) 

           apply(subgoal_tac
"uint
                 (word_of_int
                   (foldl (\<lambda>u. bin_cat u 8) 0 (map uint (output_address cl))) :: 256 word)
 = int cl")
    apply(case_tac vi)
          apply(clarsimp)
          apply(simp add:Word.int_word_uint)

          defer (* more gross math here *)

          (* setup for applying determinism of descends *)
    apply(subgoal_tac
"
(((0, length x2a), ttree),
 ((a, b), llt.LLab cpre cj),
ej @ st)
\<in> ll3'_descend
"
)
       apply(frule_tac k = ej in ll3_descend_nonnil)
       apply(rotate_tac -2)
       apply(drule_tac ll3_descend_splitpath)
       apply(clarsimp)
    apply(case_tac st)
        apply(simp)
       apply(clarsimp)

    apply(drule_tac k = "hd#tl" in ll_descend_eq_r2l)
apply(drule_tac k = "hd#tl" in ll_descend_eq_r2l)
apply(clarsimp)

(* then apply valid3'_desc_full *)
       apply(rotate_tac -1)
       apply(drule_tac "ll_descend_eq_l2r")
    apply(rotate_tac -1)
       apply(frule_tac ll_valid3'_desc_full)
        apply(simp)
    apply(frule_tac k = ed in ll3_descend_nonnil)
       apply(clarsimp)
       apply(rotate_tac -1)
       apply(drule_tac ll_valid3'.cases)
             apply(simp_all)
       apply(clarsimp) apply(rotate_tac -1)
    apply(drule_tac x = "ac#lista" in spec)
       apply(clarsimp)
       apply(safe)

(* "does-not-exist" case *)
        apply(clarsimp)
        apply(rotate_tac -1)
        apply(drule_tac x = a in spec) apply(rotate_tac -1)
    apply(drule_tac x = b in spec) apply(rotate_tac -1)
        apply(drule_tac x = cpre in spec) apply(rotate_tac -1)
    apply(drule_tac k = "ac#lista" in ll_descend_eq_r2l)
        apply(clarsimp)
        apply(simp add:ll_descend_eq_l2r)

(* exists-case *)
       apply(drule_tac k = "ac#lista" in ll_descend_eq_r2l)
       apply(drule_tac k = "ac#lista" in ll_descend_eq_r2l)
       apply(clarsimp)

(* deferred goals *)
      apply(case_tac "ej@st")
       apply(clarsimp)
      apply(clarsimp)
      apply(rule_tac ll_descend_eq_l2r)
      apply(clarsimp)

           apply(drule_tac t = "ttree"
                  and ad = "(cl, b)"
                  and d = "llt.LLab cpre cj"  in qvalid_get_node1)
    apply(simp)
    apply(rotate_tac -1)
    apply(drule_tac qvalid_llab) apply(simp)


    (* deferred "gross math" goal *)
    (* we are missing something here, as compared
to the other proof.

 cl mod 115792089237316195423570985008687907853269984665640564039457584007913129639936
 nat (foldl (\<lambda>u. bin_cat u 8) 0 (map uint (output_address cl)) mod
      115792089237316195423570985008687907853269984665640564039457584007913129639936) 
 *)
 apply(subgoal_tac
   "cl mod 115792089237316195423570985008687907853269984665640564039457584007913129639936 =
 nat (foldl (\<lambda>u. bin_cat u 8) 0 (map uint (output_address cl)) mod 115792089237316195423570985008687907853269984665640564039457584007913129639936) 
 ")
            apply(subgoal_tac "cl < 2^256")
         apply(simp add: Word_Miscellaneous.nat_mod_eq')
        apply(subgoal_tac "length (output_address cl) \<le> 32")
        apply(cut_tac cl = cl in output_address_length_bound)
         apply(simp)
         apply(case_tac "length (output_address cl) = 32")
         apply(simp)
    
           apply(subgoal_tac
"256 ^ (length (output_address cl) :: nat) <
 (256 ^ 32 :: nat)")
    apply(simp)
    apply(rule_tac  Power.linordered_semidom_class.power_strict_increasing)
          apply(simp (no_asm_simp)) 
    apply(simp (no_asm_simp)) 
    apply(simp (no_asm_simp)) 

    apply(cut_tac cl = cl in ElleAltSemantics.reconstruct_address_gen2)
    apply(simp) 
    done
  
next
  case (7 t cp x e d n cc net elst' st st')
  then show ?case
    apply(auto)
    apply(case_tac fuel, clarify) apply(simp)
    apply(frule_tac valid3'_qvalid) apply(simp)
    apply(simp split:option.split_asm)
     apply(frule_tac cp = cp and a = "(0, tend)" and t = ttree in program_list_of_lst_validate_head1) apply(auto)
         apply(drule_tac qvalid_get_node1[rotated 1]) apply(simp)
    apply(rotate_tac -1)
      apply(frule_tac ll_valid_q.cases, auto)

         apply(frule_tac qvalid_desc_bounded1) apply(simp) apply(simp)
    apply(frule_tac qvalid_codegen'_check1, simp) apply(simp) apply(simp)
     apply(simp add:program.defs) apply(auto)
         apply(drule_tac qvalid_get_node1[rotated 1]) apply(simp)
     apply(rotate_tac -1) apply(frule_tac ll_valid_q.cases, auto)

(* heck yes *)
    apply(simp add:clearpc'_def )
(*    apply(case_tac "check_resources (vi\<lparr>vctx_pc := 0\<rparr>) (clearprog' cc) (vctx_stack vi)
            (Pc JUMPDEST) net") apply(clarsimp) *)
    apply(simp add:check_resources_def)
(*
    apply(simp add:elle_stop_def)
        apply(simp add:program.defs clearprog'_def elle_stop_def check_resources_def)
*)
    apply(frule_tac program_list_of_lst_validate_jmpi1)
       apply(simp) apply(simp) apply(simp)
    apply(clarsimp)

    apply(frule_tac valid3'_qvalid)
    apply(frule_tac cp = "cp" in qvalid_get_node1[rotated 1]) apply(auto simp del:elle_instD'.simps program_sem.simps)
     apply(frule_tac cp = "cp" in qvalid_desc_bounded1[rotated 1]) apply(auto simp del:elle_instD'.simps program_sem.simps)
    apply(rotate_tac -2)
    apply(frule_tac ll_valid_q.cases, auto)


    apply(case_tac " length (output_address e) = n")
     apply(clarsimp) apply(auto)
    apply(case_tac "output_address e = []") apply(clarsimp)
     apply(clarsimp)
     apply(case_tac "32 < length (output_address e)")
      apply(clarsimp)
apply(clarsimp)

    apply(auto simp add:program.defs)
(* *** branching starts here *** *)
    apply(split if_split_asm)
    apply(clarsimp)
                             

      apply(case_tac "x2b ! a", auto)
    apply(auto simp add:program.defs)

    apply(case_tac nata)
        apply(clarsimp)
       apply(clarsimp)

    apply(simp add:check_resources_def)
    apply(case_tac "inst_stack_numbers
                  (x2b ! nat (int a + (1 + int (length (output_address e)))))")
       apply(clarsimp)

    apply(subgoal_tac
" x2b ! nat (int a + (1 + int (length (output_address e))))
= Pc JUMPI"
)
     apply(auto)

     apply (split if_split_asm)
      apply(clarsimp)
     apply(clarsimp)
     apply(case_tac "vctx_stack vi")
      apply(clarsimp)
     apply(clarsimp)
    apply(auto simp add:Evm.strict_if_def)
     apply(case_tac "aa = 0")
      apply(clarsimp)
    apply(simp add:check_resources_def)

    apply(case_tac nata)
    apply(clarsimp)
    apply(clarsimp)

    (* need fact about how we are at the end of x2b *)
    apply(drule_tac qvalid_cp_next_None1[rotated 1])
    apply(clarsimp)
    apply(clarsimp)
    apply(clarsimp)
        apply(simp add:check_resources_def)
        apply(auto)

        apply(subgoal_tac
      "
nat (int a + (1 + int (length (output_address e))))
=
 Suc (a + length (output_address e))
"
)

        apply(clarsimp)
    apply(auto simp add:Int.nat_int Int.nat_int_add )        
    done
next
case (8 t cp x e d n cc net st st' st'')
    (* should not be so different from 7. currently code is just copied *)
    then show ?case
        apply(auto)
    apply(case_tac fuel, clarify) apply(simp)
    apply(frule_tac valid3'_qvalid) apply(simp)
         apply(frule_tac qvalid_get_node1[rotated 1]) apply(simp)
    apply(rotate_tac -1)
      apply(frule_tac ll_valid_q.cases, auto)

      apply(rotate_tac -1)

      (* *** current point *** *)
      
      apply(frule_tac qvalid_desc_bounded1) apply(simp) apply(simp)
      apply(case_tac "codegen'_check ((0, tend), ttree)") apply(simp)
      apply(clarsimp)
      apply(case_tac " program_list_of_lst_validate aa")
      apply(simp)
      apply(clarsimp)
    apply(frule_tac qvalid_codegen'_check1, simp) apply(simp) apply(simp)
     apply(simp add:program.defs) apply(auto)
         apply(frule_tac qvalid_get_node1[rotated 1]) apply(simp)
     apply(rotate_tac -1) apply(drule_tac ll_valid_q.cases, auto)

(* heck yes *)
    apply(simp add:clearpc'_def )
(*    apply(case_tac "check_resources (vi\<lparr>vctx_pc := 0\<rparr>) (clearprog' cc) (vctx_stack vi)
            (Pc JUMPDEST) net") apply(clarsimp) *)
    apply(simp add:check_resources_def)
(*
    apply(simp add:elle_stop_def)
        apply(simp add:program.defs clearprog'_def elle_stop_def check_resources_def)
*)
    apply(frule_tac t = ttree in program_list_of_lst_validate_jmpi1)
       apply(simp) apply(simp) apply(simp)
    apply(clarsimp)

    apply(rotate_tac 1)
    apply(frule_tac cp = "x" in qvalid_get_node1[rotated 1]) apply(auto simp del:elle_instD'.simps program_sem.simps)
     apply(frule_tac cp = "x" in qvalid_desc_bounded1[rotated 1]) apply(auto simp del:elle_instD'.simps program_sem.simps)
(*    apply(rotate_tac -2)
    apply(frule_tac ll_valid_q.cases, auto) *)


    apply(case_tac " length (output_address d) = cc")
     apply(clarsimp) apply(auto)
    apply(case_tac "output_address d = []") apply(clarsimp)
     apply(clarsimp)
     apply(case_tac "32 < length (output_address d)")
      apply(clarsimp)
apply(clarsimp)

                             

apply(case_tac "ab ! ac", auto)

(* *** branching starts here *** *)

    apply(split if_split_asm)
    apply(clarsimp)

    
        apply(split if_split_asm)
    apply(clarsimp)
    apply(auto simp add:program.defs)

    apply(case_tac nata, auto)
    apply(simp add:check_resources_def)
    apply(subgoal_tac
      "(ab ! nat (int ac + (1 + int (length (output_address d))))) = Pc JUMPI"
      )
    apply(auto)
   apply(subgoal_tac
      "
nat (int ac + (1 + int (length (output_address d))))
=
 Suc (ac + length (output_address d))
"
)
        apply(clarsimp)
        apply(auto simp add:Int.nat_int Int.nat_int_add )        

        
         apply (split if_split_asm)
         apply(clarsimp)
              apply(case_tac "vctx_stack vi")
              apply(clarsimp)
                  apply(auto simp add:program.defs)
    apply(case_tac nata, auto)
    apply(simp add:check_resources_def)
    apply(subgoal_tac
      "(ab ! nat (int ac + (1 + int (length (output_address d))))) = Pc JUMPI"
      )
    apply(auto)
   apply(subgoal_tac
      "
nat (int ac + (1 + int (length (output_address d))))
=
 Suc (ac + length (output_address d))
"
)
        apply(clarsimp)
        apply(auto simp add:Int.nat_int Int.nat_int_add )        

        apply(auto simp add:Evm.strict_if_def)
     apply(case_tac "a = 0")
     apply(clarsimp)
     apply(case_tac nata, auto)
     apply(simp add:check_resources_def)
         apply(subgoal_tac
      "(ab ! nat (int ac + (1 + int (length (output_address d))))) = Pc JUMPI"
      )
         apply(auto)
         defer
   apply(subgoal_tac
      "
nat (int ac + (1 + int (length (output_address d))))
=
 Suc (ac + length (output_address d))
"
)        apply(clarsimp)
        apply(auto simp add:Int.nat_int Int.nat_int_add )        

        apply(drule_tac qvalid_cp_next_Some1)
        apply(auto)

        apply(drule_tac x = act in spec)
        apply(rotate_tac -1)
        apply(drule_tac x = vc in spec)
        apply(rotate_tac -1)
        apply(drule_tac x = venv in spec)
        apply(rotate_tac -1)
        apply(auto)        
        apply(rotate_tac -1)
        apply(drule_tac x = nata in spec)
        apply(case_tac vi, clarsimp)        
    done

next
  case (9 t cp cc net x e st st')
  then show ?case
    apply(auto)
    apply(split option.split_asm, auto)
    apply(split option.split_asm, auto)
     apply(frule_tac valid3'_qvalid)
    apply(frule_tac qvalid_cp_next_None1) apply(auto)
    apply(frule_tac qvalid_codegen'_check1) apply(auto)

    apply(frule_tac qvalid_get_node1, auto)
    apply(rotate_tac -1) apply(drule_tac ll_valid_q.cases, auto)
    apply(drule_tac ll_validl_q.cases, auto)

    apply(case_tac fuel, auto)

        apply(split option.split_asm, auto)
     apply(split option.split_asm, auto)
    apply(simp add:program.defs clearprog'_def check_resources_def)
(* OK, i guess the issue is that we need to check for an initial state
that isn't invalid? i guess somewhere in the label case
these checks already happened or something *)
(* or perhaps the issue is that we should get failures
later on? *)
(* should stop be using next_state? *)
    apply(simp add:clearpc'_def) apply(auto)
          apply(simp add:program.defs clearprog'_def check_resources_def)
(* huh, simp sets seem different? *)
apply(simp add:program.defs clearprog'_def check_resources_def inst_stack_numbers.simps misc_inst_numbers.simps) 

    done
next
  case (10 t cp x e cp' cc net z z')
  then show ?case
    apply(auto)
    apply(split option.split_asm, auto)
    apply(split option.split_asm, auto)
    apply(drule_tac x = targend in spec, auto)
     apply(frule_tac valid3'_qvalid)
     apply(frule_tac qvalid_cp_next_Some1) apply(auto)

     apply(frule_tac valid3'_qvalid)
    apply(frule_tac qvalid_get_node1, auto)
    apply(rotate_tac -1) apply(drule_tac ll_valid_q.cases, auto)
    apply(rotate_tac -1) apply(drule_tac ll_validl_q.cases, auto)

    apply(drule_tac x = act in spec)
    apply(drule_tac x = vc in spec)
    apply(drule_tac x = venv in spec)
    apply(clarsimp)
    done
next
  case (11 t cp x e h rest cc net z z')
  then show ?case
    apply(auto)
    apply(split option.split_asm, auto)
    apply(split option.split_asm, auto)
    apply(frule_tac kl = 0 in ll_get_node_last2) apply(auto)
    apply(case_tac h, auto)
    apply(frule_tac valid3'_qvalid)
    apply(frule_tac qvalid_get_node1, auto)
    apply(rotate_tac -1) apply(drule_tac ll_valid_q.cases, auto)
    apply(rotate_tac -1) apply(drule_tac ll_validl_q.cases, auto)

        apply(drule_tac x = act in spec)
    apply(drule_tac x = vc in spec)
    apply(drule_tac x = venv in spec)
    apply(clarsimp)
    done
qed


theorem elle_alt_correct_fail :
"elle_alt_sem ((t :: ll4)) cp cc net st st' \<Longrightarrow>
 (t \<in> ll_valid3' \<longrightarrow>
  (! tend ttree . t = ((0, tend), ttree) \<longrightarrow>
 ll4_validate_jump_targets [] t \<longrightarrow>
 (! targstart targend tdesc . ll_get_node t cp = Some ((targstart, targend), tdesc) \<longrightarrow>
   (! vi . st = InstructionContinue vi \<longrightarrow>
    (* require that prog already be loaded beofre this point? *)
   (! prog . ll4_load_lst_validate cc t = Some prog \<longrightarrow>
   (! act vc venv fuel stopper . program_sem stopper
               prog 
               fuel net 
(* is this arithmetic around fst (fst t) right? *)
(* perhaps we need a secondary proof that validity implies
that targstart will be greater than or equal to fst (fst t) *)
               (setpc_ir st (targstart  (*- fst (fst t) *))) = 
                   (* fuel can be arbitrary, but we require to compute to a final result *)
                   InstructionToEnvironment act vc venv \<longrightarrow>
( ? l . act = ContractFail l)  \<longrightarrow> 
                  (* the issue may have to do with distinguishing between errors? *)
                  (* TODO: in some cases we end up having to compare unloaded programs? *)
(? lsem vcsem venvsem .
   st' = InstructionToEnvironment (ContractFail lsem) vcsem venvsem)
))))))"
(*  using [[simp_debug]] *)
(*  using [[simp_trace_new mode=full]] *)
(*  using [[simp_trace_depth_limit=20]] *)
(*  using [[linarith_split_limit=12]] *)
proof(induction rule:elle_alt_sem.induct)
case (1 t cp x e i cc net st st' st'')
then show ?case
apply(clarify)
    apply(simp only:Hoare.execution_continue)
    apply(case_tac fuel)
     apply(simp)
    apply(clarify)
    apply(frule_tac my_exec_continue)

        apply(simp del:elle_instD'.simps program_sem.simps)
    apply(case_tac "codegen'_check ((0, tend), ttree)", simp)
    apply(simp del:elle_instD'.simps program_sem.simps)
    apply(frule_tac valid3'_qvalid)
    apply(frule_tac qvalid_get_node1[rotated 1]) apply(auto simp del:elle_instD'.simps program_sem.simps)
    apply(frule_tac qvalid_cp_next_None1) apply(auto simp del:elle_instD'.simps program_sem.simps)
    print_state
    apply(frule_tac ll_L_valid_bytes_length) 
    apply(frule_tac qvalid_desc_bounded1) apply(auto simp del:elle_instD'.simps program_sem.simps)
    apply(case_tac " codegen'_check ((0, targend), ttree)", auto simp del:elle_instD'.simps program_sem.simps)
    apply(case_tac "program_list_of_lst_validate a", auto simp del:elle_instD'.simps program_sem.simps)
    apply(frule_tac cp = cp and a = "(0, targend)" and t = ttree in program_list_of_lst_validate_head1)
    (* OK, here we should use Hoare.execution_continue and the fact we just proved about inst_valid *)
        apply(safe)

        apply(auto simp del:elle_instD'.simps program_sem.simps)

    apply(rotate_tac -5) apply(drule_tac ll_valid_q.cases)
        apply(auto simp del:elle_instD'.simps program_sem.simps)

    print_state
     apply(frule_tac qvalid_codegen'_check1)
        apply(auto simp del:elle_instD'.simps program_sem.simps)


    apply(frule_tac cc = "(clearprog' cc)"
and cc' = "(cc\<lparr>cctx_program := program.make (\<lambda>i. index aa (nat i)) (int (length aa))\<rparr>)"
and vcstart = "(vi\<lparr>vctx_pc := int 0\<rparr>)"
and vcstart' = "(vi\<lparr>vctx_pc := int ab\<rparr>)" (*targstart? *)
and irfinal = "st'"
and n = net
in elle_instD'_correct)         apply(auto simp del:elle_instD'.simps program_sem.simps)

        apply(simp add:clearpc'_def del:elle_instD'.simps program_sem.simps)
       apply(simp add:clearprog'_def del:elle_instD'.simps program_sem.simps)
      apply(simp add:program.simps program.defs del:elle_instD'.simps program_sem.simps)
(* case_tac *)
      apply(simp add:program.simps program.defs clearpc'_def elle_stop.simps del:elle_instD'.simps program_sem.simps)
(* case split to see if we are already at I2E or we need
to actually run elle_stop*)
(* looks decent up until here *)
    print_state

        apply(case_tac "program_sem (\<lambda>_. ()) (cc\<lparr>cctx_program := \<lparr>program_content = \<lambda>i. index aa (nat i), program_length = int (length aa)\<rparr>\<rparr>) (Suc 0) net
              (InstructionContinue (vi\<lparr>vctx_pc := int ab\<rparr>))")
      apply(drule_tac x = x1 in spec)

     apply(simp del:instruction_sem_def next_state_def)
    apply(case_tac "check_resources (vi\<lparr>vctx_pc := 0\<rparr>) (clearprog' cc) (vctx_stack vi)
             (aa ! ab) net")
    apply(case_tac " check_resources (x1\<lparr>vctx_pc := 0\<rparr>) (clearprog' cc) (vctx_stack x1)
            (Misc STOP) net")
       apply(simp del:instruction_sem_def next_state_def)
       apply(simp add:instruction_sem_def)
       apply(case_tac nata, simp del:instruction_sem_def next_state_def)
       apply(simp del:instruction_sem_def next_state_def)
       apply(simp add:instruction_sem_def check_resources_def)

       apply(case_tac nata, simp del:instruction_sem_def next_state_def)
      apply(simp add:instruction_sem_def check_resources_def)
(* something different needed here *)
    print_state
    apply(clarsimp)

    apply(case_tac " program_sem (\<lambda>_. ())
           (cc\<lparr>cctx_program :=
                 \<lparr>program_content = \<lambda>i. index aa (nat i),
                    program_length = int ab + int (length (inst_code (aa ! ab)))\<rparr>\<rparr>)
           (Suc 0) net (InstructionContinue (vi\<lparr>vctx_pc := int ab\<rparr>))")
       apply(simp del:instruction_sem_def next_state_def)
       apply(simp del:instruction_sem_def next_state_def)
    
    done
       
next
case (2 t cp x e i cc net cp' st st' st'')
then show ?case

    
        apply(clarify)
    apply(simp only:Hoare.execution_continue)
    apply(case_tac fuel)
     apply(simp)
    apply(clarify)
    apply(frule_tac my_exec_continue)
    apply(simp del:elle_instD'.simps program_sem.simps)
    apply(case_tac "codegen'_check ((0, tend), ttree)", simp)
    apply(simp del:elle_instD'.simps program_sem.simps)
    apply(frule_tac valid3'_qvalid)
    apply(frule_tac qvalid_get_node1[rotated 1]) apply(auto simp del:elle_instD'.simps program_sem.simps)
    apply(frule_tac qvalid_cp_next_Some1) apply(auto simp del:elle_instD'.simps program_sem.simps)
    print_state
    apply(frule_tac ll_L_valid_bytes_length) 
    apply(frule_tac qvalid_desc_bounded1) apply(auto simp del:elle_instD'.simps program_sem.simps)
    apply(case_tac "program_list_of_lst_validate a")
    apply(simp del:elle_instD'.simps program_sem.simps)
    apply(simp del:elle_instD'.simps program_sem.simps)

    apply(case_tac " codegen'_check ((0, tend), ttree)", auto simp del:elle_instD'.simps program_sem.simps)
    apply(case_tac "program_list_of_lst_validate a", auto simp del:elle_instD'.simps program_sem.simps)
    apply(frule_tac cp = cp and a = "(0, tend)" and t = ttree in program_list_of_lst_validate_head1)
    (* OK, here we should use Hoare.execution_continue and the fact we just proved about inst_valid *)
        apply(safe)

        apply(auto simp del:elle_instD'.simps program_sem.simps)

    apply(rotate_tac -7) apply(drule_tac ll_valid_q.cases)
        apply(auto simp del:elle_instD'.simps program_sem.simps)

    print_state
     apply(frule_tac qvalid_codegen'_check1)
        apply(auto simp del:elle_instD'.simps program_sem.simps)

(* need lemma for permuting elle_stop and pc_update *)
(* i think this one isn't quite right though *)

    apply(frule_tac cc = "(setprog' cc bogus_prog)"
and cc' = "(cc\<lparr>cctx_program := program.make (\<lambda>i. index aa (nat i)) (int (length aa))\<rparr>)"
and vcstart = "(vi\<lparr>vctx_pc := int 0\<rparr>)"
and vcstart' = "(vi\<lparr>vctx_pc := int ab\<rparr>)" (*targstart? *)
and irfinal = "st'"
and n = net
in elle_instD'_correct) 
        apply(auto simp del:elle_instD'.simps program_sem.simps)
    print_state
        apply(simp_all add:clearpc'_def clearprog'_def setprog'_def del:elle_instD'.simps program_sem.simps)
     apply(simp add:program.simps program.defs del:elle_instD'.simps program_sem.simps)
     apply(case_tac " inst_code (aa ! ab)")
      apply(simp) apply(simp)

    (*1 goal. things seem ok up until here *)
    apply(simp add:program.simps program.defs del:elle_instD'.simps program_sem.simps)
    apply(case_tac "elle_instD' (aa ! ab) (cc\<lparr>cctx_program := bogus_prog\<rparr>) net
              (InstructionContinue (vi\<lparr>vctx_pc := 0\<rparr>))")
      apply(drule_tac x = x1 in spec)
     apply(simp del:instruction_sem_def next_state_def)
     apply(case_tac "check_resources (vi\<lparr>vctx_pc := 0\<rparr>) (cc\<lparr>cctx_program := bogus_prog\<rparr>) (vctx_stack vi) (aa ! ab) net")
     apply(simp del:instruction_sem_def next_state_def)
    apply(case_tac "next_state (\<lambda>_. ()) (cc\<lparr>cctx_program := \<lparr>program_content = \<lambda>i. index aa (nat i), program_length = int (length aa)\<rparr>\<rparr>) net
           (InstructionContinue (vi\<lparr>vctx_pc := int ab\<rparr>))")
       apply(case_tac "index aa ab")
        apply(auto simp del:instruction_sem_def next_state_def) (* was auto *)
    print_state
    apply(case_tac " check_resources (vi\<lparr>vctx_pc := int ab\<rparr>) (cc\<lparr>cctx_program := \<lparr>program_content = \<lambda>i. index aa (nat i), program_length = int (length aa)\<rparr>\<rparr>)
            (vctx_stack vi) (Misc STOP) net")
       apply(simp)           
       apply(simp)
       
    apply(case_tac "check_resources (vi\<lparr>vctx_pc := int ab\<rparr>)
            (cc\<lparr>cctx_program :=
                  \<lparr>program_content = \<lambda>i. index aa (nat i), program_length = int (length aa)\<rparr>\<rparr>)
            (vctx_stack vi) (aa ! ab) net")
      apply(drule_tac x = "ContractFail l" in spec)
      apply(auto)                                         
        apply(drule_tac x = vc in spec)
        apply(drule_tac x = venv in spec)
        apply(drule_tac x = nata in spec)
              apply(case_tac x1) apply(case_tac x1a)
    apply(clarify)
      apply(auto)

   
(* final goal *)
(* under construction  *)
(* need case_tac nata? *)
     apply(case_tac "index aa ab")
     apply(clarsimp del:instruction_sem_def next_state_def)
     apply(case_tac "inst_code (aa ! ab)", auto)

    apply(case_tac " check_resources (vi\<lparr>vctx_pc := int ab\<rparr>) (cc\<lparr>cctx_program := \<lparr>program_content = \<lambda>i. index aa (nat i), program_length = int (length aa)\<rparr>\<rparr>)
             (vctx_stack vi) (aa ! ab) net")
    apply(simp only:)
     apply(simp del:instruction_sem_def next_state_def check_resources_def)

     apply(case_tac "check_resources (vi\<lparr>vctx_pc := 0\<rparr>) (cc\<lparr>cctx_program := bogus_prog\<rparr>) (vctx_stack vi) (aa ! ab) net")
    apply(simp only:)
      apply(simp del:instruction_sem_def next_state_def check_resources_def)

    apply(case_tac nata)
       apply(simp del:instruction_sem_def next_state_def check_resources_def)

    apply(frule_tac elle_alt_sem_halted)
      apply(simp del:instruction_sem_def next_state_def check_resources_def)

    apply(frule_tac elle_alt_sem_halted)
      apply(simp del:instruction_sem_def next_state_def check_resources_def)
      apply(clarify)

      apply(simp del:instruction_sem_def check_resources_def)

(* next_state_halted?
need to show that b/c we start in
a ToEnvironment state,
that same state is returned in the end *)

    apply(case_tac "
 instruction_sem (vi\<lparr>vctx_pc := int ab\<rparr>)
               (cc\<lparr>cctx_program :=
                     \<lparr>program_content = \<lambda>i. index aa (nat i), program_length = int (length aa)\<rparr>\<rparr>)
               (aa ! ab) net
")
      apply(simp del:instruction_sem_def check_resources_def)
      apply(simp del:instruction_sem_def check_resources_def)

    apply(simp only:)

     apply(frule_tac elle_alt_sem_halted)
     apply(simp only: split:if_splits, clarify)

(* need a lemma about check_resources
if two cctx differ only in programs

 *)
      apply(frule_tac
  v' = "(vi\<lparr>vctx_pc := 0\<rparr>)" and
  c' =  "(cc\<lparr>cctx_program := bogus_prog\<rparr>)" and
  pc' = 0 and
  prog' = bogus_prog in
 check_resources_gen) apply(clarify)
        apply(simp del:instruction_sem_def check_resources_def)
       apply(simp del:instruction_sem_def check_resources_def)
      apply(clarify)

(*      
    apply(case_tac " check_resources (vi\<lparr>vctx_pc := 0\<rparr>) (cc\<lparr>cctx_program := bogus_prog\<rparr>)
            (vctx_stack vi) (aa ! ab) net") *)
            (* *** specialize differently here *** *)
           apply(frule_tac
  v' = "(vi\<lparr>vctx_pc := 0\<rparr>)" and
  c' =  "(cc\<lparr>cctx_program := bogus_prog\<rparr>)" and
  pc' = 0 and
  prog' = "bogus_prog" in
 check_resources_gen) apply(clarify)
       apply(simp (no_asm_simp))
      apply(simp (no_asm_simp))
      apply(clarify)

      apply(case_tac " check_resources (vi\<lparr>vctx_pc := 0\<rparr>) (cc\<lparr>cctx_program := bogus_prog\<rparr>) (vctx_stack vi) (aa ! ab) net")
        apply(simp del:instruction_sem_def meter_gas_def inst_stack_numbers.simps check_resources_def)
        apply(clarify)      
                   apply(frule_tac
  v' = "(vi\<lparr>vctx_pc := ab\<rparr>)" and
  c' =  "(cc\<lparr>cctx_program :=
              \<lparr>program_content = \<lambda>i. index aa (nat i),
                 program_length = int (length aa )\<rparr>\<rparr>)" and
  pc' = ab and
  prog' = "\<lparr>program_content = \<lambda>i. index aa (nat i),
                 program_length = int (length aa )\<rparr>" in
 check_resources_gen) apply(clarify)
        apply(simp (no_asm_simp))
      apply(simp (no_asm_simp))
      apply(clarify)

        apply(simp del:instruction_sem_def meter_gas_def inst_stack_numbers.simps check_resources_def)
      apply(clarify)
      apply(frule_tac elle_alt_sem_halted)

      apply( auto simp del:instruction_sem_def meter_gas_def inst_stack_numbers.simps check_resources_def)

     done
next
case (3 t cp x e d cc net st st' st'')
then show ?case
    apply(clarify)
    apply(case_tac fuel, clarify) apply(simp)

    apply(frule_tac valid3'_qvalid) apply(simp)
    apply(simp split:option.split_asm)
     apply(frule_tac cp = cp and a = "(0, tend)" and t = ttree in program_list_of_lst_validate_head1) apply(auto)
         apply(drule_tac qvalid_get_node1[rotated 1]) apply(simp)
    apply(rotate_tac -1)
      apply(frule_tac ll_valid_q.cases, auto)

         apply(frule_tac qvalid_desc_bounded1) apply(simp) apply(simp)
    apply(frule_tac qvalid_codegen'_check1, simp) apply(simp) apply(simp)
     apply(simp add:program.defs) apply(auto)
         apply(drule_tac qvalid_get_node1[rotated 1]) apply(simp)
     apply(rotate_tac -1) apply(frule_tac ll_valid_q.cases, auto)

(* heck yes *)
    apply(simp add:clearpc'_def )
(*    apply(case_tac "check_resources (vi\<lparr>vctx_pc := 0\<rparr>) (clearprog' cc) (vctx_stack vi)
            (Pc JUMPDEST) net") apply(clarsimp) *)
    apply(simp add:check_resources_def)
(*
    apply(simp add:elle_stop_def)
        apply(simp add:program.defs clearprog'_def elle_stop_def check_resources_def)
*)
    apply(subgoal_tac "x2a = Pc JUMPDEST")
    apply(clarsimp)
(*     apply(auto) (* was just auto 3 3 *) *)
(* now we need the fact about the length running out *)
      apply(simp add:program.defs clearprog'_def check_resources_def)
(* we will prove this subgoal later with "head" theorem,
can delete hypotheses to make computation faster if we need *)
       apply(clarsimp)
       apply(frule_tac qvalid_codegen'_check1, auto)
       apply(case_tac nata, auto)
    apply(split option.split_asm)
    apply(split option.split_asm) 
         apply(auto)
    apply(split option.split_asm) 
        apply(auto)
      apply(simp add:program.defs clearprog'_def check_resources_def)
       apply(simp add:program.defs clearprog'_def check_resources_def)
       apply(frule_tac qvalid_cp_next_None1, auto)
       apply(frule_tac qvalid_get_node1, auto) apply(rotate_tac -1)
       apply(drule_tac ll_valid_q.cases, auto)


    apply(frule_tac program_list_of_lst_validate_head1, auto)
     apply(frule_tac qvalid_get_node1, auto)
     apply(rotate_tac -1)
     apply(drule_tac ll_valid_q.cases, auto)
    apply(simp add:program.defs)
    done
next
case (4 st'' t cp x e d cp' cc net st st')
then show ?case 
        apply(clarify)
    apply(case_tac fuel, clarify) apply(simp)

(* need to be careful about where exactly we are doing reasoning with qvalid
so that we can minimize the size of these scripts *)
    apply(frule_tac valid3'_qvalid) apply(simp) apply(clarify)
         apply(frule_tac qvalid_get_node1[rotated 1]) apply(simp)
    apply(rotate_tac -1)
    apply(frule_tac ll_valid_q.cases, auto)
    apply(case_tac "codegen'_check ((0, tend), ttree)", auto)
    apply(case_tac " program_list_of_lst_validate aa", auto)
    apply(frule_tac a = "(0, tend)" and adl = a in program_list_of_lst_validate_head1, auto) 

    apply(simp split:option.split_asm) apply(auto)
         apply(frule_tac qvalid_desc_bounded1) apply(simp) apply(simp)
    apply(frule_tac qvalid_codegen'_check1, simp) apply(simp) apply(simp)
     apply(simp add:program.defs) 

    apply(frule_tac qvalid_cp_next_Some1, auto)
    apply(simp add:program.defs clearprog'_def check_resources_def)
    apply(auto)
    apply(case_tac "ab ! a", auto)


    apply(case_tac " clearpc' (InstructionContinue vi)", auto)
    apply(simp add:program.defs clearprog'_def check_resources_def)

     apply(case_tac "int (length (vctx_stack x1)) \<le> 1024 \<and> 1 \<le> vctx_gas x1", auto)
       apply(simp add:program.defs clearprog'_def check_resources_def clearpc'_def)
    apply(case_tac "ab ! a", auto)
    apply(simp add:program.defs clearprog'_def check_resources_def clearpc'_def)
    apply(drule_tac x = "ContractFail l" in spec)
    apply(clarsimp)
    apply(drule_tac x = vc in spec) apply(drule_tac x = venv in spec)
    apply(drule_tac x = nata in spec)
    apply(subgoal_tac "1 + int a = int a + 1") apply(case_tac vi)
    apply(clarsimp)
    apply(simp)
    
    apply(frule_tac elle_alt_sem_halted)
    apply(clarsimp)

    apply(frule_tac elle_alt_sem_halted)
    apply(clarsimp)

         apply(case_tac "int (length (vctx_stack vi)) \<le> 1024 \<and> 1 \<le> vctx_gas vi", auto)
       apply(simp add:program.defs clearprog'_def check_resources_def clearpc'_def)
       apply(simp add:program.defs clearprog'_def check_resources_def clearpc'_def)
           apply(simp add:program.defs clearprog'_def check_resources_def clearpc'_def)

           done

next
case (5 xl el dl t cpre cj xj ej dj nj cl cc net st st' st'')
then show ?case

    apply(auto)
    apply(simp add:clearpc'_def)
     apply(split option.split_asm, auto)
     apply(split option.split_asm, auto)
     apply(case_tac fuel, auto)
     apply(split option.split_asm, auto)
          apply(split option.split_asm, auto)

     (*apply(split option.split_asm, auto)*) (* this is probably splitting the wrong thing *)

     
     apply(case_tac t, auto)


(* ensure these are applying to the correct descends fact
i.e., the JUMP
*)
(* we need to apply some additional lemma here (but what exactly?) *)
    apply(case_tac "codegen'_check ((0, tend), ttree)", simp)
    apply(simp del:elle_instD'.simps program_sem.simps)
    apply(frule_tac valid3'_qvalid)
    apply(frule_tac cp = "cpre @ cj" in qvalid_get_node1[rotated 1]) apply(auto simp del:elle_instD'.simps program_sem.simps)
    print_state
(*   apply(rotate_tac 2) *)
     apply(frule_tac cp = "cpre @ cj" in qvalid_desc_bounded1[rotated 1]) apply(auto simp del:elle_instD'.simps program_sem.simps)

      apply(frule_tac program_list_of_lst_validate_jmp1)
         apply(auto simp del:elle_instD'.simps program_sem.simps)

       apply(case_tac ild2, auto)
       apply(case_tac "length (output_address ej) = nj", auto)
       apply(case_tac "output_address ej = []", auto)
    apply(case_tac "32 < length (output_address ej) ", auto)

    apply(case_tac " program_content (program.make (\<lambda>i. index x2a (nat i)) (int (length x2a))) (int targstart)")
     apply(auto simp add:program.defs)

    apply(rotate_tac 16)
    apply(frule_tac ll_valid_q.cases, auto)

     
     (* old proof follows *)

    print_state
    apply(simp add:check_resources_def)
    apply(case_tac "x2a ! a", auto)


          apply(case_tac "vctx_gas vi < 11")
       apply(auto simp del:elle_instD'.simps program_sem.simps)
       apply(frule_tac elle_alt_sem_halted) apply(auto)

       apply(case_tac "1024 \<le> int (length (vctx_stack vi))")
           apply(auto simp del:elle_instD'.simps program_sem.simps)
       apply(frule_tac elle_alt_sem_halted) apply(auto)

(* *** current point, doing more heavy-weight proof modifications ***  *)
    
    apply(case_tac "program_content (program.make (\<lambda>i. index x2a (nat i)) (int (length x2a))) (int a)")
     apply(auto simp add:program.defs)

     apply(case_tac nata, auto)


     apply(subgoal_tac
       "x2a ! nat (int a + (1 + int (length (output_address ej)))) = Pc JUMP")

     apply(subgoal_tac "(uint (word_of_int (foldl (\<lambda>u. bin_cat u 8) 0 (map uint (output_address ej))) :: 256 word)) =  ej")
     
     apply(simp add:check_resources_def)
     apply(split option.split_asm) apply(clarsimp)
     apply(split option.split_asm) apply(clarsimp) apply(clarsimp)

     (* need validate_jump_targets_spec *)
     apply(case_tac "cpre@cj") apply(clarsimp)
     apply(clarsimp)
     apply(frule_tac kh = aa in ll_descend_eq_l2r) 
     apply(frule_tac validate_jump_targets_spec)
     apply(simp)

     (* branching begins *)
     (* *** do we want to try to extract
information about x2b = JUMPDEST here? *)
  apply(simp)
     apply(safe)
     apply(clarsimp)

     apply(drule_tac ll_valid3'.cases)
     apply(simp_all)
     apply(clarsimp)
     apply(case_tac xl, clarsimp)

     apply(frule_tac k = k in ll_descend_eq_r2l)
          apply(drule_tac k = k and  q' = "(ac, bb)" in ll_descend_eq_r2l)
          apply(case_tac k) apply(clarsimp)
          apply(clarsimp)
     apply(frule_tac adl = ej and cp = "ad#lista" in program_list_of_lst_validate_head1)
     apply(simp_all)

     defer (* label fact *)
     apply(clarsimp) (* need to know ej < length x2a *)
     apply(subgoal_tac "ej < length x2a")
     apply(clarsimp)
     apply(case_tac "index x2a ej") apply(clarsimp) 
     apply(case_tac "x2a ! ej", auto)

     apply(case_tac "cpre @ cl") apply(clarsimp)
     apply(clarsimp)

     (* cpre should be nil *)
     apply(case_tac cpre) apply(clarsimp)


     apply(drule_tac x = "ac#listb" in spec) apply(clarsimp)
     apply(drule_tac kh = "ac" and kt = listb
                     and e = e and q = "(0, length x2a)" in ll_descend_eq_l2r_list)
     apply(subgoal_tac "(\<exists>a b ba.
           (((0, length x2a), llt.LSeq e la), ((a, b), llt.LLab ba (length listb)),
            ac # listb)
           \<in> ll3'_descend)")
     apply(clarsimp)

     apply(rotate_tac -1)
     apply(drule_tac ll_descend_eq_r2l)
     apply(rotate_tac -2)
     apply(drule_tac ll_descend_eq_r2l)
     apply(clarsimp)

     apply(drule_tac x = "ContractFail l" in spec)
     apply(clarsimp)
     apply(case_tac vi) apply(clarsimp)
     
     (* proof of subgoal thesis (hypothesis of lemma about descended labels being equal) *)
     apply(rule_tac x = ab in exI)
     apply(rule_tac x = ba in exI)
     apply(rule_tac x = el in exI)
     apply(clarsimp)
     
     (* proof that cpre is nil *)
     apply(clarify)
     apply(simp)
     apply(clarify)
     apply(simp (no_asm_use))

     (* proof about ej, boundednesss *)
     apply(frule_tac cp = "ad#lista" and ad = "(ej, bb)" and d = " llt.LLab True (length lista)"  in qvalid_get_node2) apply(clarsimp)
     apply(drule_tac qvalid_llab) apply(clarsimp)
     apply(drule_tac nd = ej and nd' = bb and cp = "ad#lista" and desc = " llt.LLab True (length lista)" in qvalid_desc_bounded1) apply(clarsimp) apply(clarsimp)

     (* other big case, then deferred goals *)

     (* first, prove descendent is valid.
then repeat case above. *)
apply(frule_tac k = cpre in ll_valid3'_desc_full) apply(clarsimp)
apply(rotate_tac -1)
          apply(drule_tac ll_valid3'.cases)
     apply(simp_all)
     apply(clarsimp)
     apply(case_tac xl, clarsimp)
     apply(case_tac k) apply(clarsimp)
     apply(clarsimp)

     apply(frule_tac ll_get_node_comp2) apply(clarsimp)
     apply(frule_tac k = cpre in ll_descend_eq_r2l)
     apply(clarsimp)
          apply(frule_tac k = "ae#lista" in ll_descend_eq_r2l)
          apply(clarsimp)
          apply(case_tac cl) apply(clarsimp)
          apply(clarsimp)
          apply(drule_tac x = "ac#listb" in spec)

          apply(clarsimp)

          apply(subgoal_tac "(\<exists>a b ba.
           (((af, bd), llt.LSeq e la), ((a, b), llt.LLab ba (length listb)),
            ac # listb)
           \<in> ll3'_descend)")
          apply(clarsimp)

          apply(subgoal_tac "index x2a ej = Some (Pc JUMPDEST)")
          apply(clarsimp)
          apply(case_tac "x2a ! ej", auto)


          apply(drule_tac x = "ContractFail l" in spec) apply(clarsimp)
          apply(case_tac vi) apply(clarsimp)

               apply(frule_tac cp = "cpre@ac#listb" and ad = "(ej, ba)" and d = " llt.LLab el (length listb)"  in qvalid_get_node1) apply(clarsimp)
     apply(drule_tac qvalid_llab) apply(clarsimp)
     apply(drule_tac nd = ej and nd' = ba and cp = "cpre@ac#listb" and desc = " llt.LLab el (length listb)" in qvalid_desc_bounded1) apply(clarsimp) apply(clarsimp)

     apply(frule_tac adl = ej and adr = ba and d = " llt.LLab el (length listb)"
 and cp = "cpre @ ac # listb" in program_list_of_lst_validate_head1)
     apply(clarsimp)
                    apply(frule_tac cp = "cpre@ac#listb" and ad = "(ej, ba)" and d = " llt.LLab el (length listb)"  in qvalid_get_node1) apply(clarsimp)
                    apply(drule_tac qvalid_llab) apply(clarsimp)
                    apply(clarsimp) apply(simp_all)

                    apply(clarsimp)

                    apply(rotate_tac -1)
                    apply(drule_tac x = ab in spec)
                    apply(rotate_tac -1)
                    apply(drule_tac x = b in spec)
                    apply(rotate_tac -1)
                    apply(drule_tac x = el in spec)
                    apply(simp add:ll_descend_eq_l2r)

                    (* deferred goals *)
                    apply(simp add:Word.int_word_uint)
                            apply(subgoal_tac
                              "
 nat (foldl (\<lambda>u. bin_cat u 8) 0
        (map uint (output_address ej)) mod
       115792089237316195423570985008687907853269984665640564039457584007913129639936) =
       ej
")
                            apply(simp)
                            apply(cut_tac cl = ej in reconstruct_address_gen2)                    
        apply(subgoal_tac "ej < 2^256")
         apply(simp add: Word_Miscellaneous.nat_mod_eq')
        apply(simp)
        apply(subgoal_tac "length (output_address ej) \<le> 32")
        apply(cut_tac cl = ej in output_address_length_bound)
         apply(simp)
         apply(case_tac "length (output_address ej) = 32")
          apply(simp)
    apply(subgoal_tac
"256 ^ (length (output_address ej) :: nat) <
 (256 ^ 32 :: nat)")
    apply(simp)
    apply(rule_tac  Power.linordered_semidom_class.power_strict_increasing)
          apply(simp (no_asm_simp)) 
    apply(simp (no_asm_simp)) 
    apply(simp (no_asm_simp)) 

    (* next deferred goal *)
    apply(subgoal_tac "nat (int a + (1 + int (length (output_address ej)))) = 
Suc (a + length (output_address ej))")
    apply(simp)
    apply(simp add:Int.nat_int_add)

    apply(drule_tac cp = "ad#lista" in qvalid_get_node2) apply(simp_all)
    apply(rotate_tac -1) apply(drule_tac qvalid_llab) apply(simp)
    done

next
case (6 xl el dl t cpre cj xj ej dj nj cl cc net st st' st'')
then show ?case 

(* ***
preamble from case 5
*** *)
    apply(auto)
    apply(simp add:clearpc'_def)
     apply(split option.split_asm, auto)
     apply(split option.split_asm, auto)
     apply(case_tac fuel, auto)
     apply(split option.split_asm, auto)
          apply(split option.split_asm, auto)

     (*apply(split option.split_asm, auto)*) (* this is probably splitting the wrong thing *)

     
     apply(case_tac t, auto)


(* ensure these are applying to the correct descends fact
i.e., the JUMP
*)
(* we need to apply some additional lemma here (but what exactly?) *)
    apply(case_tac "codegen'_check ((0, tend), ttree)", simp)
    apply(simp del:elle_instD'.simps program_sem.simps)
    apply(frule_tac valid3'_qvalid)
    apply(frule_tac cp = "cpre @ cj" in qvalid_get_node1[rotated 1]) apply(auto simp del:elle_instD'.simps program_sem.simps)
    print_state
(*   apply(rotate_tac 2) *)
     apply(frule_tac cp = "cpre @ cj" in qvalid_desc_bounded1[rotated 1]) apply(auto simp del:elle_instD'.simps program_sem.simps)

      apply(frule_tac program_list_of_lst_validate_jmpi1)
         apply(auto simp del:elle_instD'.simps program_sem.simps)

       apply(case_tac ild2, auto)
       apply(case_tac "length (output_address ej) = nj", auto)
       apply(case_tac "output_address ej = []", auto)
    apply(case_tac "32 < length (output_address ej) ", auto)

    apply(case_tac " program_content (program.make (\<lambda>i. index x2a (nat i)) (int (length x2a))) (int targstart)")
     apply(auto simp add:program.defs)

    apply(rotate_tac 16)
    apply(frule_tac ll_valid_q.cases, auto)

    (* jumpI specific stuff *)
    apply(case_tac "vctx_gas vi < 13") apply(clarsimp)
    apply(clarsimp)

    apply(case_tac "1024 \<le> int (length (vctx_stack vi))") apply(clarsimp)
    apply(clarsimp)

    apply(case_tac "vctx_stack vi") apply(clarsimp)
    apply(clarsimp)

    apply(simp add: strict_if_def)
    apply(case_tac "aa = 0") apply(clarsimp)

    apply(clarsimp)

     
     (* old proof follows *)

    print_state
    apply(simp add:check_resources_def)
    apply(case_tac "x2a ! a", auto)

    (* *** current point, doing more heavy-weight proof modifications
           copied from case 5 ***  *)
    
    apply(case_tac "program_content (program.make (\<lambda>i. index x2a (nat i)) (int (length x2a))) (int a)")
     apply(auto simp add:program.defs)

     apply(case_tac nata, auto)


     apply(subgoal_tac
       "x2a ! nat (int a + (1 + int (length (output_address ej)))) = Pc JUMPI")

     apply(subgoal_tac "(uint (word_of_int (foldl (\<lambda>u. bin_cat u 8) 0 (map uint (output_address ej))) :: 256 word)) =  ej")
     
     apply(simp add:check_resources_def)
     apply(split option.split_asm) apply(clarsimp)
     apply(split option.split_asm) apply(clarsimp) apply(clarsimp)

     (* need validate_jump_targets_spec *)
     apply(case_tac "cpre@cj") apply(clarsimp)
     apply(clarsimp)
     apply(frule_tac kh = ab in ll_descend_eq_l2r) 
     apply(frule_tac validate_jump_targets_spec_jumpi)
     apply(simp)

     (* branching begins *)
     (* *** do we want to try to extract
information about x2b = JUMPDEST here? *)
  apply(simp)
     apply(safe)
     apply(clarsimp)

     apply(drule_tac ll_valid3'.cases)
     apply(simp_all)
     apply(clarsimp)
     apply(case_tac xl, clarsimp)

     apply(frule_tac k = k in ll_descend_eq_r2l)
          apply(drule_tac k = k and  q' = "(ad, bb)" in ll_descend_eq_r2l)
          apply(case_tac k) apply(clarsimp)
          apply(clarsimp)
     apply(frule_tac adl = ej and cp = "ae#listb" in program_list_of_lst_validate_head1)
     apply(simp_all)

     defer (* label fact *)
     
     apply(clarsimp) (* need to know ej < length x2a *)
     apply(subgoal_tac "ej < length x2a")
     apply(clarsimp)
     apply(case_tac "index x2a ej") apply(clarsimp) 
     apply(case_tac "x2a ! ej", auto)

     apply(case_tac "cpre @ cl") apply(clarsimp)
     apply(clarsimp)

     (* cpre should be nil *)
     apply(case_tac cpre) apply(clarsimp)


     apply(drule_tac x = "ad#listc" in spec) apply(clarsimp)
     apply(drule_tac kh = "ad" and kt = listc
                     and e = e and q = "(0, length x2a)" in ll_descend_eq_l2r_list)
     apply(subgoal_tac "(\<exists>a b ba.
           (((0, length x2a), llt.LSeq e la), ((a, b), llt.LLab ba (length listc)),
            ad # listc)
           \<in> ll3'_descend)")
     apply(clarsimp)

     apply(rotate_tac -1)
     apply(drule_tac ll_descend_eq_r2l)
     apply(rotate_tac -2)
     apply(drule_tac ll_descend_eq_r2l)
     apply(clarsimp)

     apply(drule_tac x = "ContractFail l" in spec)
     apply(clarsimp)
     apply(case_tac vi) apply(clarsimp)
     
     (* proof of subgoal thesis (hypothesis of lemma about descended labels being equal) *)
     apply(rule_tac x = ac in exI)
     apply(rule_tac x = ba in exI)
     apply(rule_tac x = el in exI)
     apply(clarsimp)
     
     (* proof that cpre is nil *)
     apply(clarify)
     apply(simp)
     apply(clarify)
     apply(simp (no_asm_use))

     (* proof about ej, boundednesss *)
     apply(frule_tac cp = "ae#listb" and ad = "(ej, bb)" and d = " llt.LLab True (length listb)"  in qvalid_get_node2) apply(clarsimp)
     apply(drule_tac qvalid_llab) apply(clarsimp)
     apply(drule_tac nd = ej and nd' = bb and cp = "ae#listb" and desc = " llt.LLab True (length listb)" in qvalid_desc_bounded1) apply(clarsimp) apply(clarsimp)

     (* other big case, then deferred goals *)

     (* first, prove descendent is valid.
then repeat case above. *)
apply(frule_tac k = cpre in ll_valid3'_desc_full) apply(clarsimp)
apply(rotate_tac -1)
          apply(drule_tac ll_valid3'.cases)
     apply(simp_all)
     apply(clarsimp)
     apply(case_tac xl, clarsimp)
     apply(case_tac k) apply(clarsimp)
     apply(clarsimp)

     apply(frule_tac ll_get_node_comp2) apply(clarsimp)
     apply(frule_tac k = cpre in ll_descend_eq_r2l)
     apply(clarsimp)
          apply(frule_tac k = "af#listb" in ll_descend_eq_r2l)
          apply(clarsimp)
          apply(case_tac cl) apply(clarsimp)
          apply(clarsimp)
          apply(drule_tac x = "ad#listc" in spec)

          apply(clarsimp)

          apply(subgoal_tac "(\<exists>a b ba.
           (((ag, bd), llt.LSeq e la), ((a, b), llt.LLab ba (length listc)),
            ad # listc)
           \<in> ll3'_descend)")
          apply(clarsimp)

          apply(subgoal_tac "index x2a ej = Some (Pc JUMPDEST)")
          apply(clarsimp)
          apply(case_tac "x2a ! ej", auto)


          apply(drule_tac x = "ContractFail l" in spec) apply(clarsimp)
          apply(case_tac vi) apply(clarsimp)

               apply(frule_tac cp = "cpre@ad#listc" and ad = "(ej, ba)" and d = " llt.LLab el (length listc)"  in qvalid_get_node1) apply(clarsimp)
     apply(drule_tac qvalid_llab) apply(clarsimp)
     apply(drule_tac nd = ej and nd' = ba and cp = "cpre@ad#listc" and desc = " llt.LLab el (length listc)" in qvalid_desc_bounded1) apply(clarsimp) apply(clarsimp)

     apply(frule_tac adl = ej and adr = ba and d = " llt.LLab el (length listc)"
 and cp = "cpre @ ad # listc" in program_list_of_lst_validate_head1)
     apply(clarsimp)
                    apply(frule_tac cp = "cpre@ad#listc" and ad = "(ej, ba)" and d = " llt.LLab el (length listc)"  in qvalid_get_node1) apply(clarsimp)
                    apply(drule_tac qvalid_llab) apply(clarsimp)
                    apply(clarsimp) apply(simp_all)

                    apply(clarsimp)

                    apply(rotate_tac -1)
                    apply(drule_tac x = ac in spec)
                    apply(rotate_tac -1)
                    apply(drule_tac x = b in spec)
                    apply(rotate_tac -1)
                    apply(drule_tac x = el in spec)
                    apply(simp add:ll_descend_eq_l2r)

                    (* deferred goals *)
                    apply(simp add:Word.int_word_uint)
                            apply(subgoal_tac
                              "
 nat (foldl (\<lambda>u. bin_cat u 8) 0
        (map uint (output_address ej)) mod
       115792089237316195423570985008687907853269984665640564039457584007913129639936) =
       ej
")
                            apply(simp)
                            apply(cut_tac cl = ej in reconstruct_address_gen2)                    
        apply(subgoal_tac "ej < 2^256")
        apply(simp add: Word_Miscellaneous.nat_mod_eq')
        (* *** 
current point
*** *)
(*
apply(frule_tac kh = ad and kt = listc
and t = " ((ac, b),
         llt.LLab el (length listc))"
and e = e and q = "" in ll_descend_eq_l2r_list)
*)
        apply(simp)
        apply(subgoal_tac "length (output_address ej) \<le> 32")
        apply(cut_tac cl = ej in output_address_length_bound)
         apply(simp)
         apply(case_tac "length (output_address ej) = 32")
          apply(simp)
    apply(subgoal_tac
"256 ^ (length (output_address ej) :: nat) <
 (256 ^ 32 :: nat)")
    apply(simp)
    apply(rule_tac  Power.linordered_semidom_class.power_strict_increasing)
          apply(simp (no_asm_simp)) 
    apply(simp (no_asm_simp)) 
    apply(simp (no_asm_simp)) 

    (* next deferred goal *)
    apply(subgoal_tac "nat (int a + (1 + int (length (output_address ej)))) = 
Suc (a + length (output_address ej))")
    apply(simp)
    apply(simp add:Int.nat_int_add)

    apply(drule_tac cp = "ae#listb" in qvalid_get_node2) apply(simp_all)
    apply(rotate_tac -1) apply(drule_tac qvalid_llab) apply(simp)
    done


next
case (7 t cp x e d n cc net st st' st'')
then show ?case 

    apply(auto)
    apply(case_tac fuel, clarify) apply(simp)
    apply(frule_tac valid3'_qvalid) apply(simp)
    apply(simp split:option.split_asm)
     apply(frule_tac cp = cp and a = "(0, tend)" and t = ttree in program_list_of_lst_validate_head1) apply(auto)
         apply(drule_tac qvalid_get_node1[rotated 1]) apply(simp)
    apply(rotate_tac -1)
      apply(frule_tac ll_valid_q.cases, auto)

         apply(frule_tac qvalid_desc_bounded1) apply(simp) apply(simp)
    apply(frule_tac qvalid_codegen'_check1, simp) apply(simp) apply(simp)
     apply(simp add:program.defs) apply(auto)
         apply(drule_tac qvalid_get_node1[rotated 1]) apply(simp)
     apply(rotate_tac -1) apply(frule_tac ll_valid_q.cases, auto)

(* heck yes *)
    apply(simp add:clearpc'_def )
(*    apply(case_tac "check_resources (vi\<lparr>vctx_pc := 0\<rparr>) (clearprog' cc) (vctx_stack vi)
            (Pc JUMPDEST) net") apply(clarsimp) *)
    apply(simp add:check_resources_def)
(*
    apply(simp add:elle_stop_def)
        apply(simp add:program.defs clearprog'_def elle_stop_def check_resources_def)
*)
    apply(frule_tac program_list_of_lst_validate_jmpi1)
       apply(simp) apply(simp) apply(simp)
    apply(clarsimp)

    apply(frule_tac valid3'_qvalid)
    apply(frule_tac cp = "cp" in qvalid_get_node1[rotated 1]) apply(auto simp del:elle_instD'.simps program_sem.simps)
     apply(frule_tac cp = "cp" in qvalid_desc_bounded1[rotated 1]) apply(auto simp del:elle_instD'.simps program_sem.simps)
    apply(rotate_tac -2)
    apply(frule_tac ll_valid_q.cases, auto)


    apply(case_tac " length (output_address e) = n")
     apply(clarsimp) apply(auto)
    apply(case_tac "output_address e = []") apply(clarsimp)
     apply(clarsimp)
     apply(case_tac "32 < length (output_address e)")
      apply(clarsimp)
apply(clarsimp)

    apply(auto simp add:program.defs)
(* *** branching starts here *** *)

      apply(case_tac "x2b ! a", auto)

    apply(split if_split_asm)
    apply(clarsimp)
                             
    apply(case_tac "vctx_gas vi < 13")
    apply(clarsimp)

    apply(split option.split_asm)
    apply(clarsimp)
    apply(case_tac "vctx_stack vi")
    apply(clarsimp)
    apply(clarsimp)

    apply(simp add:strict_if_def)
    apply(case_tac "aa = 0")
    apply(clarsimp)
    
    apply(split option.split_asm)
    apply(clarsimp)
    apply(clarsimp)

    apply(split option.split_asm)
    apply(clarsimp)
    apply(clarsimp)

    apply(clarsimp)
        apply(case_tac "vctx_stack vi")
    apply(clarsimp)
    apply(clarsimp)

        apply(simp add:strict_if_def)
    apply(case_tac "aa = 0")
    apply(clarsimp)

        apply(split option.split_asm)
    apply(clarsimp)
    apply(auto simp add:program.defs)

    apply(case_tac nata)
        apply(clarsimp)
       apply(clarsimp)

        apply(split option.split_asm)
    apply(clarsimp)
        apply(split option.split_asm)
    apply(clarsimp)
    apply(clarsimp)

        apply(split option.split_asm)
    apply(clarsimp)
    
    apply(simp add:check_resources_def)
    apply(simp add:check_resources_def)
    apply(case_tac "x2b ! a", auto)

    apply(subgoal_tac
      "(x2b ! nat (int a + (1 + int (length (output_address e))))) = Pc JUMPI"
      )
    apply(clarsimp)

    apply(case_tac nata)
    apply(clarsimp)
    apply(clarsimp)
    
    apply(drule_tac qvalid_cp_next_None1[rotated 1])
    apply(auto)
        apply(simp add:check_resources_def)

        apply(subgoal_tac
          "nat (int a + (1 + int (length (output_address e)))) =
 Suc (a + length (output_address e))"
 )
    
    apply(case_tac "inst_stack_numbers
                  (x2b ! nat (int a + (1 + int (length (output_address e)))))")
       apply(clarsimp)

            apply(simp add:Int.nat_int Int.nat_int_add )        


            apply(case_tac "vctx_gas vi < 13")
            apply(clarsimp)
            apply(clarsimp)        
    done

next
case (8 st'' t cp x e d n cp' cc net st st')
then show ?case
        apply(auto)
    apply(case_tac fuel, clarify) apply(simp)
    apply(frule_tac valid3'_qvalid) apply(simp)
         apply(frule_tac qvalid_get_node1[rotated 1]) apply(simp)
    apply(rotate_tac -1)
      apply(frule_tac ll_valid_q.cases, auto)

      apply(rotate_tac -1)

      (* *** current point *** *)
      
      apply(frule_tac qvalid_desc_bounded1) apply(simp) apply(simp)
      apply(case_tac "codegen'_check ((0, tend), ttree)") apply(simp)
      apply(clarsimp)
      apply(case_tac " program_list_of_lst_validate aa")
      apply(simp)
      apply(clarsimp)
    apply(frule_tac qvalid_codegen'_check1, simp) apply(simp) apply(simp)
     apply(simp add:program.defs) apply(auto)
         apply(frule_tac qvalid_get_node1[rotated 1]) apply(simp)
     apply(rotate_tac -1) apply(drule_tac ll_valid_q.cases, auto)

(* heck yes *)
    apply(simp add:clearpc'_def )
(*    apply(case_tac "check_resources (vi\<lparr>vctx_pc := 0\<rparr>) (clearprog' cc) (vctx_stack vi)
            (Pc JUMPDEST) net") apply(clarsimp) *)
    apply(simp add:check_resources_def)
(*
    apply(simp add:elle_stop_def)
        apply(simp add:program.defs clearprog'_def elle_stop_def check_resources_def)
*)
    apply(frule_tac t = ttree in program_list_of_lst_validate_jmpi1)
       apply(simp) apply(simp) apply(simp)
    apply(clarsimp)

    apply(rotate_tac 1)
    apply(frule_tac cp = "cp" in qvalid_get_node1[rotated 1]) apply(auto simp del:elle_instD'.simps program_sem.simps)
     apply(frule_tac cp = "cp" in qvalid_desc_bounded1[rotated 1]) apply(auto simp del:elle_instD'.simps program_sem.simps)
(*    apply(rotate_tac -2)
    apply(frule_tac ll_valid_q.cases, auto) *)


    apply(case_tac " length (output_address e) = n")
     apply(clarsimp) apply(auto)
    apply(case_tac "output_address e = []") apply(clarsimp)
     apply(clarsimp)
     apply(case_tac "32 < length (output_address e)")
      apply(clarsimp)
apply(clarsimp)

                             

apply(case_tac "ab ! ac", auto)

(* *** branching starts here *** *)

    apply(split if_split_asm)
    apply(clarsimp)

    
        apply(split if_split_asm)
    apply(clarsimp)
    apply(auto simp add:program.defs)

    apply(case_tac nata, auto)
    apply(simp add:check_resources_def)
    apply(subgoal_tac
      "(ab ! nat (int ac + (1 + int (length (output_address e))))) = Pc JUMPI"
      )
    apply(auto)
   apply(subgoal_tac
      "
nat (int ac + (1 + int (length (output_address e))))
=
 Suc (ac + length (output_address e))
"
)
        apply(clarsimp)
        apply(auto simp add:Int.nat_int Int.nat_int_add )        

        apply(frule_tac elle_alt_sem_halted) apply(auto)

        apply(subgoal_tac
          "
 nat (int ac + (1 + int (length (output_address e)))) = Suc (ac + length (output_address e))"
 )
        apply(simp)
        apply(simp add:Int.nat_int Int.nat_int_add )        

        apply(frule_tac elle_alt_sem_halted) apply(auto)
    
        apply(frule_tac elle_alt_sem_halted) apply(auto)

        (* back to 1 goal *)
        apply(split if_split_asm)
        apply(clarsimp)
        apply(case_tac "vctx_stack vi")
        apply(clarsimp)

        apply(frule_tac elle_alt_sem_halted) apply(auto)

        apply(simp add:strict_if_def)
        apply(case_tac "a = 0")
        apply(clarsimp)

        apply(split option.split_asm)
        apply(clarsimp)

                apply(split option.split_asm)
                apply(clarsimp)
                apply(clarsimp)

                apply(split option.split_asm)
                apply(clarsimp)
                apply(simp add:program.defs)
                
                apply(clarsimp)
                apply(simp add:program.defs)

                apply(drule_tac cp = cp and cp' = cp' in qvalid_cp_next_Some1[rotated 1])
                apply(clarsimp)
                apply(clarsimp)
                 apply(clarsimp)
                 
                apply(case_tac nata)
                apply(clarsimp)
                apply(clarsimp)

       apply(split option.split_asm)
       apply(clarsimp)
       apply(split option.split_asm)
        apply(clarsimp)
        apply(clarsimp)

        apply(split option.split_asm)
        apply(clarsimp)

        apply(simp add:check_resources_def program.defs)
        apply(simp add:check_resources_def program.defs)

        apply(clarsimp)

        apply(subgoal_tac
          "ab ! nat (int ac + int (length (inst_code (ab ! ac)))) = Pc JUMPI")
        apply(clarsimp)

        apply(drule_tac x = "ContractFail l" in spec)
        apply(clarsimp)
        apply(drule_tac x = vc in spec)
        apply(drule_tac x = venv in spec)
        apply(drule_tac x = nata in spec)
        apply(case_tac vi) apply(clarsimp)

        apply(subgoal_tac "length (inst_code (ab ! ac)) = 1 + length (output_address e)")        
        apply( simp add:check_resources_def program.defs)
        apply(simp)
        apply(case_tac "ab ! ac", auto)

        apply(auto simp add:Int.nat_int Int.nat_int_add )        
                apply(subgoal_tac "length (inst_code (ab ! ac)) = 1 + length (output_address e)")        
        apply( simp add:check_resources_def program.defs)
        apply(simp)
        apply(case_tac "ab ! ac", auto)

        apply(frule_tac elle_alt_sem_halted)
        apply(auto) 
    done

next
case (9 t cp cc net x e st st')
then show ?case

    apply(auto)
    apply(split option.split_asm, auto)
    apply(split option.split_asm, auto)
     apply(frule_tac valid3'_qvalid)
    apply(frule_tac qvalid_cp_next_None1) apply(auto)
    apply(frule_tac qvalid_codegen'_check1) apply(auto)

    apply(frule_tac qvalid_get_node1, auto)
    apply(rotate_tac -1) apply(drule_tac ll_valid_q.cases, auto)
    apply(drule_tac ll_validl_q.cases, auto)

    apply(case_tac fuel, auto)

        apply(split option.split_asm, auto)
     apply(split option.split_asm, auto)
    apply(simp add:program.defs clearprog'_def check_resources_def)

    apply(simp add:clearpc'_def) apply(auto)
          apply(simp add:program.defs clearprog'_def check_resources_def)

          apply(simp add:program.defs clearprog'_def check_resources_def inst_stack_numbers.simps misc_inst_numbers.simps)
          apply(simp add:program.defs clearprog'_def check_resources_def inst_stack_numbers.simps misc_inst_numbers.simps)
          apply(simp add:program.defs clearprog'_def check_resources_def inst_stack_numbers.simps misc_inst_numbers.simps)
          done
next
case (10 t cp x e cp' cc net z z')
then show ?case
    apply(auto)
    apply(split option.split_asm, auto)
    apply(split option.split_asm, auto)
    apply(drule_tac x = targend in spec, auto)
     apply(frule_tac valid3'_qvalid)
     apply(frule_tac qvalid_cp_next_Some1) apply(auto)

     apply(frule_tac valid3'_qvalid)
    apply(frule_tac qvalid_get_node1, auto)
    apply(rotate_tac -1) apply(drule_tac ll_valid_q.cases, auto)
    apply(rotate_tac -1) apply(drule_tac ll_validl_q.cases, auto)

    apply(drule_tac x = "ContractFail l" in spec)
    apply(clarsimp)
    done
next
case (11 t cp x e h rest cc net z z')
then show ?case
    apply(auto)
    apply(split option.split_asm, auto)
    apply(split option.split_asm, auto)
    apply(frule_tac kl = 0 in ll_get_node_last2) apply(auto)
    apply(case_tac h, auto)
    apply(frule_tac valid3'_qvalid)
    apply(frule_tac qvalid_get_node1, auto)
    apply(rotate_tac -1) apply(drule_tac ll_valid_q.cases, auto)
    apply(rotate_tac -1) apply(drule_tac ll_validl_q.cases, auto)

        apply(drule_tac x = "ContractFail l" in spec)
    apply(clarsimp)
    done
qed 

end
