theory LLLL2
  
  imports Main "../ContractSem" "../RelationalSem" "../ProgramInAvl" "../Hoare/Hoare" "../lem/Evm"
  
begin
  
  (* LLLL, mark 2 *)

(* we need to rule out invalid, PC, and misc instrs *)
(* stack manipulation should be OK *)
fun inst_valid :: "inst => bool" where
  "inst_valid (Unknown _) = False"
| "inst_valid (Pc _) = False"
| "inst_valid (Misc _) = False"
| "inst_valid _ = True"

(* don't mix up de Bruijn indices with sizes *)  
type_synonym idx = nat
  
datatype ll1 =
  L "inst"
  (* de-Bruijn style approach to local binders *)
  | LLab "idx"
  | LJmp "idx"
  | LJmpI "idx"
  (* sequencing nodes also serve as local binders *)
  | LSeq "ll1 list"

lemma old_ll1_induct:
  assumes Ln: "(\<And> i. P1 (L i))"
  and La: "(\<And> idx . P1 (LLab idx))"
  and Lj: "(\<And>idx . P1 (LJmp idx))"
  and Lji : "(\<And>idx . P1 (LJmpI idx))"
  and Ljs : "(\<And>l . P2 l \<Longrightarrow> P1 (LSeq l))"
  and Lln : "P2 []"
  and Llc : "\<And>t l . P1 t \<Longrightarrow> P2 l \<Longrightarrow> P2 (t # l)"
  shows "P1 t \<and> P2 l"
proof-
  {fix t
    have "P1 t \<and> (\<forall> l . t = LSeq l \<longrightarrow> P2 l)"
    proof (induction)
      case (L) thus ?case using Ln by auto next
      case (LLab) thus ?case using La by auto next
      case (LJmp) thus ?case using Lj by auto next
      case (LJmpI) thus ?case using Lji by auto next
      case (LSeq l) thus ?case
        apply (induct l) using Ljs Lln Llc by auto blast+
    qed}
  
  thus ?thesis by auto
qed
          
fun ll1_valid :: "ll1 \<Rightarrow> bool" where
  "ll1_valid (L i) = inst_valid i"
  | "ll1_valid (LSeq is) = list_all ll1_valid is"
  | "ll1_valid _ = True"
  
    
(*    
datatype ll2 =
  L "int * inst * int"
  | LLab "int * idx * int"
  | LJmp "int * idx * int"
  | LJmpI "int * idx * int"
  | LSeq "int * (int * ll2 * int) list * int"
*)
(* ll2 contains a field for us to decorate label locations and jumps with paths *)
(* do we need path to be mut ind *)    
datatype ll2 =
  L "nat * inst * nat"
  | LLab "nat * idx * path2 option * nat"
  | LJmp "nat * idx * path2 option * nat"
  | LJmpI "nat * idx * path2 option * nat"
  | LSeq "nat * (nat * ll2 * nat) list * nat"
and path2 =
  Top "nat * nat" (* needs an int argument ? two? *)
  | Node "nat * (nat * ll2 * nat) list * nat * path2 * nat * (nat * ll2 * nat) list * nat"
  
    
value "(L (0, Arith ADD, 0))"


  
(* P1 is for nodes ll2, P2 is for lists of nodes ((nat * ll2 * nat) list), P3 is for paths
   (note that P3 actually takes a path option) *)  
(* does P1 also need to take nats? maybe they all do *)
 (*
lemma old_ll2_induct:
  assumes Ln: "(\<And> n i n'. P1 (L (n, i, n')) n n')"
  and La: "(\<And> n idx po n' . P3 po n n' \<Longrightarrow> P1 (LLab (n, idx, po, n')) n n')"
  and Lj: "(\<And> n idx po n' . P3 po n n' \<Longrightarrow> P1 (LJmp (n, idx, po, n')) n n')"
  and Lji : "(\<And> n idx po n' . P3 po n n' \<Longrightarrow> P1 (LJmpI (n, idx, po, n')) n n')"
  and Lsq : "(\<And> n l n' . P2 l n n' \<Longrightarrow> P1 (LSeq (n, l, n')) n n')"
  and Lln : "P2 [] 0 0"
  and Llc : "\<And> n t n' l n'' . P1 t n n' \<Longrightarrow> P2 l n' n'' \<Longrightarrow> P2 ((n, t, n') # l) n n''"
  shows "P1 t n n' \<and> P2 l m m' \<and> P3 po k k'"
  proof-
    {fix t
      (* need an existential somewhere? *)
      have "P1 t n n' \<and>
          (\<forall> l . t = LSeq (n, l, n') \<longrightarrow> P2 l n n') \<and>
          (\<forall> idx po . t = LLab (n, idx, po, n') \<longrightarrow> P3 po n n')"
    proof(induction t)
      case(L x) thus ?case using Ln
        apply(case_tac x)
        apply(clarsimp)
        apply(case_tac x)
        apply(auto)
    done
*)  
  
    
definition jump_size :: "nat" where
  "jump_size = nat (inst_size (Pc JUMP))"
  
declare jump_size_def [simp]

definition jumpi_size :: "nat" where
  "jumpi_size = nat (inst_size (Pc JUMPI))"  

declare jumpi_size_def [simp]
  
(* validity of ll2 terms that have just been translated from ll1 *)
inductive_set
  ll2_valid :: "(nat * ll2 * nat) set" and
  ll2_validl :: "(nat * ((nat * ll2 * nat) list) * nat) set" 
  where
    "\<And> i n . inst_valid i \<Longrightarrow> (n, (L (n, i, n + nat (inst_size i))), n + nat (inst_size i)) \<in> ll2_valid"
  | "\<And> n d . (n, (LLab (n, d, None, n)), n) \<in> ll2_valid"
  | "\<And> n d . (n, (LJmp (n, d, None, n+1)), n+1) \<in> ll2_valid"
  | "\<And> n d . (n, (LJmpI (n, d, None, n + 1)), n + 1) \<in> ll2_valid"
  | "\<And> n l n' . (n, l, n') \<in> ll2_validl \<Longrightarrow> (n, (LSeq (n, l, n')), n') \<in> ll2_valid  "
  | "\<And> n . (n, [], n) \<in> ll2_validl"  
  | "\<And> n h n' t n'' .
     (n, h, n') \<in> ll2_valid \<Longrightarrow>
     (n', t, n'') \<in> ll2_validl \<Longrightarrow>
     (n, ((n, h, n') # t), n'') \<in> ll2_validl"
 
  
(* we need a size-validity predicate for ll2 *)
(* we take an int indicating where we start from *)
fun ll2_valid_sz :: "ll2 \<Rightarrow> nat \<Rightarrow> (nat * bool)" and
    ll2_valid_sz_seq :: "nat \<Rightarrow> (nat * ll2 * nat) list \<Rightarrow> nat \<Rightarrow> bool" where
  "ll2_valid_sz (L (i', c, i'')) i =
   (i'',
   (inst_valid c \<and> (i' = i) \<and> (i'' = i' + nat (inst_size c))))"
| "ll2_valid_sz (LLab (i', _, _, i'')) i =
   (i'',
   (i' = i \<and> i'' = i'))"
| "ll2_valid_sz (LJmp (i', _, _, i'')) i =
   (i'',
   (i = i' \<and> i'' = i + jump_size))"
| "ll2_valid_sz (LJmpI (i', _, _, i'')) i =
   (i'',
   (i = i' \<and> i'' = i + jumpi_size))"
| "ll2_valid_sz (LSeq (i', ls, i'')) i =
   (i'',
   (i = i') \<and> ll2_valid_sz_seq i' ls i'')"
| "ll2_valid_sz_seq i [] i' =
   (i = i')"
| "ll2_valid_sz_seq i ((i', h, i'') # t) ifin =
   ((i = i') \<and>
   (ll2_valid_sz h i' = (i'', True)) \<and>
   (ll2_valid_sz_seq i'' t ifin))"
     
value "ll2_valid_sz (ll2.LJmp (n, d, None, n + 4)) n = (n + 4, True)"
  
lemma ll2_valid_test :
  shows "((n, t, n') \<in> ll2_valid \<longrightarrow> ll2_valid_sz t n = (n', True)) \<and>
         ((m, l, m') \<in> ll2_validl \<longrightarrow> ll2_valid_sz_seq m l m' = True)"
proof(induction rule: ll2_valid_ll2_validl.induct, auto)
qed  
  
type_synonym loc2 = "ll2 * path2"
  
fun ll1_size :: "ll1 \<Rightarrow> nat" and
    ll1_size_seq :: "ll1 list \<Rightarrow> nat" where
    "ll1_size (ll1.L inst) = nat (inst_size inst)"
  | "ll1_size (ll1.LLab idx) = 0"
  | "ll1_size (ll1.LJmp idx) = 1"
  | "ll1_size (ll1.LJmpI idx) = 1"
  | "ll1_size (ll1.LSeq ls) = ll1_size_seq ls"
  | "ll1_size_seq [] = 0"
  | "ll1_size_seq (h # t) = ll1_size h + ll1_size_seq t"
  
(* first pass, storing sizes *)
fun ll_phase1 :: "ll1 \<Rightarrow> nat \<Rightarrow> (ll2 * nat)" and
    ll_phase1_seq :: "ll1 list \<Rightarrow> nat \<Rightarrow> ((nat * ll2 * nat) list * nat)"
  where
  "ll_phase1 (ll1.L inst) i = (ll2.L (i, inst, i + nat (inst_size inst)), i + nat (inst_size inst))"
| "ll_phase1 (ll1.LLab idx) i = (ll2.LLab (i, idx, None, i), i)" (* labels take no room *)
| "ll_phase1 (ll1.LJmp idx) i = (ll2.LJmp (i, idx, None, 1 + i), 1 + i)" (* jumps take at least 4 bytes *)
| "ll_phase1 (ll1.LJmpI idx) i = (ll2.LJmpI (i, idx, None, 1 + i), 1 + i)"
| "ll_phase1 (ll1.LSeq ls) i =
   (let (ls', i') = ll_phase1_seq ls i in
   (ll2.LSeq (i, ls', i'), i'))"
| "ll_phase1_seq [] i = ([], i)"
| "ll_phase1_seq (h # t) i =
   (let (h', i') = ll_phase1 h i in
    (let (t', i'') = ll_phase1_seq t i' in
      ( (i, h', i') # t', i'')))"
  
definition ll_pass1 :: "ll1 \<Rightarrow> ll2" where
  "ll_pass1 l = fst (ll_phase1 l 0)"

lemma ll_phase1_size_correct :
  fixes "x" "xs"
  shows "(! i . ? x2 . (ll_phase1 x i = (x2, ll1_size x + i))) \<and>
         (! j . ? xs2 . (ll_phase1_seq xs j = (xs2, ll1_size_seq xs + j)))"
proof (induction rule: old_ll1_induct)
  case (1 inst) thus ?case by auto next
  case (2 idx) thus ?case by auto next
  case (3 idx) thus ?case by auto next
  case (4 idx) thus ?case by auto next
  case (5 l) thus ?case
    apply(clarsimp)
    apply(drule_tac x = "i" in spec)
    apply(case_tac "ll_phase1_seq l i", clarsimp)
    done next
  case 6 thus ?case by auto next
  case (7 h t) thus ?case
    apply(clarsimp)
    apply(case_tac "ll_phase1 h j", clarsimp)
    apply(case_tac "ll_phase1_seq t b", clarsimp)
    apply(drule_tac x = "j" in spec)
    apply(drule_tac x = "b" in spec)
    apply(auto)
    done next
qed
  
lemma ll_phase1_correct:
  shows  "(ll1_valid x \<longrightarrow> (! i . ? x2 . ? i' . ll_phase1 x i = (x2, i') \<and> ll2_valid_sz x2 i = (i', True))) \<and>
          (list_all ll1_valid xs \<longrightarrow>
            (! j . ? xs2 . ? j' .
              ll_phase1_seq xs j = (xs2, j') \<and>
              ll2_valid_sz_seq j xs2 j' = True))"
proof (induction rule:old_ll1_induct)
  case (1 i) thus ?case by auto next
  case (2 idx) thus ?case by auto next
  case (3 idx) thus ?case by auto next
  case (4 idx) thus ?case by auto next
  case (5 l) thus ?case
    apply(clarsimp)
    apply(case_tac "ll_phase1_seq l i", clarsimp)
    apply(drule_tac x = "i" in spec)
    apply(auto)
    done next
  case 6 thus ?case by auto next
  case (7 h t) thus ?case
    apply(clarsimp)
    apply(case_tac "ll_phase1 h j", clarsimp)
    apply(case_tac "ll_phase1_seq t b", clarsimp)
    apply(drule_tac x = "j" in spec)
    apply(drule_tac x = "b" in spec)
    apply(auto)
    done
qed
  
lemma ll_phase1_correct' :
  "(ll1_valid x \<longrightarrow> (! i . ? x2 . ? i' . ll_phase1 x i = (x2, i') \<and> (i, x2, i') \<in> ll2_valid)) \<and>
   (list_all ll1_valid xs \<longrightarrow>
    (! j . ? xs2 . ? j' . ll_phase1_seq xs j = (xs2, j') \<and> (j, xs2, j') \<in> ll2_validl))"
proof(induction rule:old_ll1_induct)
  case (1 i) thus ?case by (auto simp add:ll2_validinductinduct.simps) next
  case (2 idx) thus ?case by (auto simp add:ll2_valid.simps) next
  case (3 idx) thus ?case by (auto simp add:ll2_valid.simps) next
  case (4 idx) thus ?case by (auto simp add:ll2_valid.simps) next
  case (5 l) thus ?case
    apply(clarsimp)
    apply(case_tac "ll_phase1_seq l i", clarsimp)
    apply(drule_tac x = "i" in spec)
    apply (auto simp add:ll2_valid.simps)
    done  next
  case (6) thus ?case 
    apply(insert "ll2_valid_ll2_validl.intros")
    apply(auto)
    done next
  case(7 t l) thus ?case
    apply(clarsimp)
    apply(case_tac "ll_phase1 t j", clarsimp)
    apply(case_tac "ll_phase1_seq l b", clarsimp)
    apply(drule_tac x = "j" in spec)
    apply(drule_tac x = "b" in spec)
    apply(auto)
    apply(insert "ll2_valid_ll2_validl.intros")
    apply(auto)
    done
qed
  
value "ll_pass1 (ll1.LSeq [ll1.LLab 0, ll1.L (Arith ADD)])"
  
value "(inst_size (Arith ADD))"
  
inductive_set ll2_descend :: "(ll2 * ll2 * nat) set"
  where
    "\<And> n n' ls t .
       (n, LSeq (n, ls, n'), n') \<in> ll2_valid \<Longrightarrow>
       (_, t, _) \<in> set ls \<Longrightarrow>
       (LSeq (n, ls, n'), t, 1) \<in> ll2_descend"
  | "\<And> t t' n t'' n' .
       (t, t', n) \<in> ll2_descend \<Longrightarrow>
       (t', t'', n') \<in> ll2_descend \<Longrightarrow>
       (t, t'', n + n') \<in> ll2_descend"
  
(* validity of ll2 terms with labels resolved*)
(* Q: how do we detect label clashes? *)
inductive_set
  ll2_valid2 :: "(nat * ll2 * nat) set" and
  ll2_validl2 :: "(nat * ((nat * ll2 * nat) list) * nat) set"
  where
    "\<And> i n . inst_valid i \<Longrightarrow> (n, (L (n, i, n + nat (inst_size i))), n + nat (inst_size i)) \<in> ll2_valid2"
  | "\<And> n d . (n, (LLab (n, d, None, n)), n) \<in> ll2_valid2"
  | "\<And> n d . (n, (LJmp (n, d, None, 1+n)), 1+n) \<in> ll2_valid2"
  | "\<And> n d . (n, (LJmpI (n, d, None, 1+n)), 1+n) \<in> ll2_valid2"
  | "\<And> n l n' . (n, l, n') \<in> ll2_validl2 \<Longrightarrow>
                 (\<not> (\<exists> k . (LSeq (n, l, n'), LLab (_, k, _, _), k) \<in> ll2_descend)) \<Longrightarrow>
                 (n, (LSeq (n, l, n')), n') \<in> ll2_valid2"
  | "\<And> n l n'. (n, l, n') \<in> ll2_validl2 \<Longrightarrow>
                (\<exists>! k . (LSeq (n, l, n'), LLab (_, k, _, _), k) \<in> ll2_descend) \<Longrightarrow>
                (n, LSeq (n, l, n'), n') \<in> ll2_valid2"
  | "\<And> n . (n, [], n) \<in> ll2_validl2"  
  | "\<And> n h n' t n'' .
     (n, h, n') \<in> ll2_valid2 \<Longrightarrow>
     (n', t, n'') \<in> ll2_validl2 \<Longrightarrow>
     (n, ((n, h, n') # t), n'') \<in> ll2_validl2"

(* idea: how do we calculate label-correctness? *)
fun ll2_add_labels :: "ll2 \<Rightarrow> ll2" where
  "ll2_add_labels (L (n, i, n')) = L (n, i, n')"
   
  
(* before going further with paths, we need some path utilities
   (inspired by Huet's Zippers paper)
 *)
  
  
(* assumes our first notion of validity *)
(* TODO make this parametric w/r/t our syntax ? *)

inductive_set ll2_validl_rev :: "(nat * ((nat * ll2 * nat) list) * nat) set" where
    "\<And> n . (n, [], n) \<in> ll2_validl_rev"
  | "\<And> n l n' h n''.
    (n', h, n'') \<in> ll2_valid \<Longrightarrow>
    (n, l, n') \<in> ll2_validl_rev \<Longrightarrow>
    (n, (n',h,n'')#l, n'') \<in> ll2_validl_rev"
    
    
  (* NOT DONE *)
  (* Q: should path correctness just be indexed to where root is in buffer? *)
  (* Q: better to have a few mut.ind. sets? *)
  (* we are using the first notion of validity *)
    (*
inductive_set path2_valid :: "(nat * loc2 * nat) set" where
  "\<And> n n'.
   (n, t, n') \<in> ll2_valid2 \<Longrightarrow>
   (n, (t, Top (n, n')), n') \<in> path2_valid"
|"\<And> n n' m m' up.
   (n', t, n'') \<in> ll2_valid2 \<Longrightarrow>
   (k, up, k') \<in> path2_valid \<Longrightarrow>
   (n, l, n') \<in>  \<Longrightarrow>
   (k, (t, Node(n, [], n, up, n', [], n')), k') \<in> path2_valid"
|"\<And>
   (n', t, n'') \<in> ll2_valid2 \<Longrightarrow>
   (x, newl, n) \<in> ll2_valid2
   (k, (t, Node(n, l, n', up, n'', r, n''')), k') \<in> path2_valid \<Longrightarrow>
   (k, (t, Node(x, (l@[(newl)]), n'  , k') \<in> path2_valid"
|"\<And> 
   (n', t, n'') \<in> ll2_valid2 \<Longrightarrow>
   (k, (t, Node(n, l, n', up, n'', r, n''')), k') \<in> path2_valid \<Longrightarrow>
   (k, (t, Node(
 \<Longrightarrow>" *)
  
fun go_left :: "loc2 \<Rightarrow> loc2" where
  "go_left (t, path2.Node(n, (m,h,m')#ls, n', up, rs, n'')) = 
           (l, path2.Node(n, ls, n', up, ()#rs, n''))"
  | "go_left loc = loc"