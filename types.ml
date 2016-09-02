module Lbool = struct
  type t =
    | LTrue
    | LFalse
    | LUndef

  let bool_of_lbool lb =
    match lb with
    | LTrue -> true
    | _ -> false
  let lbool_of_bool b = if b then LTrue else LFalse
  let inv lb = match lb with | LTrue -> LFalse | LFalse -> LTrue | LUndef -> LUndef
  let chap lb b = if b then inv lb else lb
end

module Lit = struct
  type t = int (* { *)
  (*   id : int; *)
  (*   sign : bool; *)
  (* } *)
  type lit = t

  module Array = struct
    type t = lit array
    let get t i = t.(i)
    let set t i v = t.(i) <- v
    let size t = Array.length t
    let iter f t = Array.iter f t
    let fold f a t = Array.fold_left f a t
  end

  let lit i b = if b then 2*i +1 else 2*i
  let toInt l = l
  let toLit i = if i > 0 then lit i false else lit (-i) true
  let tild l = l lxor 1
  let sign l = if (l land 1) = 1 then true else false
  let var l = l lsr 1
  let unsign l = l land (lnot 1)
  let id l b =  l lxor (if b then 1 else 0)

  let eq l p = l = p
  let neq l p = l <> p
  let lt l p = l < p
  (* let int_of_lit t = t.id *)
  (* let lit_of_int i = {id=i;value=Lbool.LUndef;} *)
  (* let bool_of_lit t = t.value *)
  (* let lit_of_bool b = {id=(-1);value=Lbool.lbool_of_bool b;} *)
  (* let lit i b = {id=(if b then 2*i else (2*i)+1);value=Lbool.LUndef;} *)
  (* let lit_of_int_bool i b = {id=i;value=Lbool.lbool_of_bool b;} *)
  (* let comp i j = i.id = j.id && j.value = i.value *)
end

module Clause = struct

  type extra =
    | Abst of int  (* int32 dans minisat: sizeof = 4 *)
    | Act of float (* float dans minisat: sizeof = 4 *)

  type t = {
    mutable size : int;
    (* suffisement petit pour pouvoir caser learnt dedans *)
    mutable extra : extra;
    learnt : bool;
    (* dans minisat: casé dans le bit de poids faible de la taille *)

    (* mutable b2 : bool; *)
    (* mutable b3 : bool; *)
    (* dans minisat ce sont les bits 2 et 3 de size_etc *)

    data : Lit.Array.t;
    (* Dans minisat c'est alloué contigue au record *)
  }

  let calc_abstraction ps =
    let abstraction = ref 0 in
    for i = 0 to Lit.Array.size ps - 1 do
      abstraction :=
        !abstraction lor
        (1 lsl ((Lit.var (Lit.Array.get ps i)) land 31))
    done;
    !abstraction

  let clause_new (ps:Lit.Array.t) ~learnt =
    let extra =
      if learnt then Act 0.
      else Abst (calc_abstraction ps)
    in
    { size = Lit.Array.size ps;
      extra;
      data = ps;
      learnt;
      (* b2 = false; *)
      (* b3 = false *)
    }

  let size t = t.size

  let get_activity = function
    | { extra = Act a } -> a
    | _ -> invalid_arg "Clause.activity"

  let set_activity t f =
    t.extra <- Act f

  let abstraction = function
    | { extra = Abst a } -> a
    | _ -> invalid_arg "Clause.abstraction"

  let shrink t i =
    assert(i < size t);
    t.size <- t.size - i

  let pop t = shrink t 1

  let learnt t = t.learnt

  (* let set_mark t (b2, b3) = *)
  (*   t.b2 <- b2; *)
  (*   t.b3 <- b3 *)

  (* let get_mark t = *)
  (*   t.b2, t.b3 *)

  let last t = Lit.Array.get t.data (size t - 1)

  let get t i = Lit.Array.get t.data i

  let set t i v = Lit.Array.set t.data i v

  let data t = t.data

  let iter f t =
    Lit.Array.iter f t.data

  let fold f a t =
    Lit.Array.fold f a t.data
end
