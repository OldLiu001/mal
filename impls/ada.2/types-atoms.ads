with Garbage_Collected;

package Types.Atoms is

   type Instance (<>) is abstract new Garbage_Collected.Instance with private;

   --  Built-in functions.
   function Atom  (Args : in T_Array) return T;
   function Deref (Args : in T_Array) return T;
   function Reset (Args : in T_Array) return T;
   function Swap  (Args : in T_Array) return T;

   --  Helper for print.
   function Deref (Item : in Instance) return T with Inline;

private

   type Instance is new Garbage_Collected.Instance with record
      Data : T;
   end record;

   overriding procedure Keep_References (Object : in out Instance) with Inline;

end Types.Atoms;
