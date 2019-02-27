with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Strings.Unbounded;
with Ada.Text_IO.Unbounded_IO;
with Interfaces.C.Strings;

with Core;
with Environments;
with Printer;
with Reader;
with Types.Functions;
with Types.Lists;
with Types.Mal;
with Types.Maps;
with Types.Symbols.Names;

procedure Step9_Try is

   package ASU renames Ada.Strings.Unbounded;
   use Types;
   use type Symbols.Ptr;

   function Read (Source : in String) return Mal.T
     renames Reader.Read_Str;

   function Eval (Ast0 : in Mal.T;
                  Env0 : in Environments.Ptr) return Mal.T;

   function Quasiquote (Ast : in Mal.T;
                        Env : in Environments.Ptr) return Mal.T;
   function Quasiquote (List : in Lists.Ptr;
                        Env  : in Environments.Ptr) return Mal.T with Inline;
   --  Handle vectors and lists not starting with unquote.
   --  Mergeing quote and quasiquote into eval with a flag triggering
   --  a different behaviour as done for macros in step8 would improve
   --  the performances significantly, but Kanaka finds that it breaks
   --  too much the step structure shared by all implementations.

   function Print (Ast      : in Mal.T;
                   Readably : in Boolean := True) return ASU.Unbounded_String
     renames Printer.Pr_Str;

   function Rep (Source : in String;
                 Env    : in Environments.Ptr) return ASU.Unbounded_String
   is (Print (Eval (Read (Source), Env))) with Inline;

   procedure Interactive_Loop (Repl : in Environments.Ptr);

   function Eval_Elements is new Lists.Generic_Eval (Environments.Ptr, Eval);
   function Eval_Elements is new Maps.Generic_Eval (Environments.Ptr, Eval);

   --  Convenient when the result of eval is of no interest.
   procedure Discard (Ast : in Mal.T) is null;

   ----------------------------------------------------------------------

   function Eval (Ast0 : in Mal.T;
                  Env0 : in Environments.Ptr) return Mal.T is
      --  Use local variables, that can be rewritten when tail call
      --  optimization goes to <<Restart>>.
      Ast            : Mal.T            := Ast0;
      Env            : Environments.Ptr := Env0.Copy_Pointer;
      Macroexpanding : Boolean          := False;
      First          : Mal.T;
   begin
      <<Restart>>
      --  Ada.Text_IO.New_Line;
      --  Ada.Text_IO.Put ("EVAL: ");
      --  Ada.Text_IO.Unbounded_IO.Put_Line (Print (Ast));
      --  Environments.Dump_Stack;
      case Ast.Kind is
      when Kind_Symbol =>
         return Env.Get (Ast.Symbol);
      when Kind_Map =>
         return Eval_Elements (Ast.Map, Env);
      when Kind_Vector =>
         return (Kind_Vector, Eval_Elements (Ast.L, Env));
      when Kind_List =>
         if Ast.L.Length = 0 then
            return Ast;
         end if;
         First := Ast.L.Element (1);
         --  Special forms
         if First.Kind /= Kind_Symbol then
            --  Evaluate First, in the less frequent case where it is
            --  not a symbol.
            First := Eval (First, Env);
         elsif First.Symbol = Symbols.Names.Def then
            if Ast.L.Length /= 3 then
               raise Argument_Error with "def!: expects 2 arguments";
            elsif Ast.L.Element (2).Kind /= Kind_Symbol then
               raise Argument_Error with "def!: arg 1 must be a symbol";
            end if;
            return R : constant Mal.T := Eval (Ast.L.Element (3), Env) do
               Env.Set (Ast.L.Element (2).Symbol, R);
            end return;
         elsif First.Symbol = Symbols.Names.Defmacro then
            if Ast.L.Length /= 3 then
               raise Argument_Error with "defmacro!: expects 2 arguments";
            elsif Ast.L.Element (2).Kind /= Kind_Symbol then
               raise Argument_Error with "defmacro!: arg 1 must be a symbol";
            end if;
            declare
               F : constant Mal.T  := Eval (Ast.L.Element (3), Env);
            begin
               if F.Kind /= Kind_Function then
                  raise Argument_Error with "defmacro!: expects a function";
               end if;
               return R : constant Mal.T := F.Function_Value.New_Macro do
                  Env.Set (Ast.L.Element (2).Symbol, R);
               end return;
            end;
         elsif First.Symbol = Symbols.Names.Mal_Do then
            if Ast.L.Length = 1 then
               raise Argument_Error with "do: expects at least 1 argument";
            end if;
            for I in 2 .. Ast.L.Length - 1 loop
               Discard (Eval (Ast.L.Element (I), Env));
            end loop;
            Ast := Ast.L.Element (Ast.L.Length);
            goto Restart;
         elsif First.Symbol = Symbols.Names.Fn then
            if Ast.L.Length /= 3 then
               raise Argument_Error with "fn*: expects 3 arguments";
            elsif Ast.L.Element (2).Kind not in Kind_List | Kind_Vector then
               raise Argument_Error with "fn*: arg 1 must be a list or vector";
            elsif (for some F in 1 .. Ast.L.Element (2).L.Length =>
                     Ast.L.Element (2).L.Element (F).Kind /= Kind_Symbol)
            then
               raise Argument_Error with "fn*: arg 2 must contain symbols";
            end if;
            return Functions.New_Function (Ast.L.Element (2).L,
                                           Ast.L.Element (3), Env.New_Closure);
         elsif First.Symbol = Symbols.Names.Mal_If then
            if Ast.L.Length not in 3 .. 4 then
               raise Argument_Error with "if: expects 2 or 3 arguments";
            end if;
            declare
               Test : constant Mal.T := Eval (Ast.L.Element (2), Env);
            begin
               if (case Test.Kind is
                   when Kind_Nil => False,
                   when Kind_Boolean => Test.Ada_Boolean,
                   when others => True)
               then
                  Ast := Ast.L.Element (3);
                  goto Restart;
               elsif Ast.L.Length = 3 then
                  return Mal.Nil;
               else
                  Ast := Ast.L.Element (4);
                  goto Restart;
               end if;
            end;
         elsif First.Symbol = Symbols.Names.Let then
            if Ast.L.Length /= 3 then
               raise Argument_Error with "let*: expects 3 arguments";
            elsif Ast.L.Element (2).Kind not in Kind_List | Kind_Vector then
               raise Argument_Error with "let*: expects a list or vector";
            end if;
            declare
               Bindings : constant Lists.Ptr := Ast.L.Element (2).L;
            begin
               if Bindings.Length mod 2 /= 0 then
                  raise Argument_Error with "let*: odd number of bindings";
               end if;
               Env.Replace_With_Sub;
               for I in 1 .. Bindings.Length / 2 loop
                  if Bindings.Element (2 * I - 1).Kind /= Kind_Symbol then
                     raise Argument_Error with "let*: keys must be symbols";
                  end if;
                  Env.Set (Bindings.Element (2 * I - 1).Symbol,
                           Eval (Bindings.Element (2 * I), Env));
               end loop;
               Ast := Ast.L.Element (3);
               goto Restart;
            end;
         elsif First.Symbol = Symbols.Names.Macroexpand then
            if Ast.L.Length /= 2 then
               raise Argument_Error with "macroexpand: expects 1 argument";
            end if;
            Macroexpanding := True;
            Ast := Ast.L.Element (2);
            goto Restart;
         elsif First.Symbol = Symbols.Names.Quasiquote then
            if Ast.L.Length /= 2 then
               raise Argument_Error with "quasiquote: expects 1 argument";
            end if;
            return Quasiquote (Ast.L.Element (2), Env);
         elsif First.Symbol = Symbols.Names.Quote then
            if Ast.L.Length /= 2 then
               raise Argument_Error with "quote: expects 1 argument";
            end if;
            return Ast.L.Element (2);
         elsif First.Symbol = Symbols.Names.Try then
            if Ast.L.Length = 2 then
               Ast := Ast.L.Element (2);
               goto Restart;
            elsif Ast.L.Length /= 3 then
               raise Argument_Error with "try*: expects 1 or 2 arguments";
            elsif Ast.L.Element (3).Kind /= Kind_List then
               raise Argument_Error with "try*: argument 2 must be a list";
            end if;
            declare
               A3 : constant Lists.Ptr := Ast.L.Element (3).L;
            begin
               if A3.Length /= 3 then
                  raise Argument_Error with "try*: arg 2 must have 3 elements";
               elsif A3.Element (1).Kind /= Kind_Symbol
                 or else A3.Element (1).Symbol /= Symbols.Names.Catch
               then
                  raise Argument_Error with "try*: arg 2 must be a catch*";
               elsif A3.Element (2).Kind /= Kind_Symbol then
                  raise Argument_Error with "catch*: expects a symbol";
               end if;
               begin
                  return Eval (Ast.L.Element (2), Env);
               exception
                  when E : Reader.Empty_Source | Argument_Error
                    | Reader.Reader_Error | Environments.Unknown_Key =>
                     Env.Replace_With_Sub;
                     Env.Set (A3.Element (2).Symbol,
                              Mal.T'(Kind_String, ASU.To_Unbounded_String
                                 (Ada.Exceptions.Exception_Message (E))));
                     Ast := A3.Element (3);
                     goto Restart;
                  when Core.Exception_Throwed =>
                     Env.Replace_With_Sub;
                     Env.Set (A3.Element (2).Symbol, Core.Last_Exception);
                     Core.Last_Exception := Mal.Nil;
                     Ast := A3.Element (3);
                     goto Restart;
                  --  Other exceptions are unexpected.
               end;
            end;
         else
            --  Equivalent to First := Eval (First, Env), except that
            --  we already know enough to spare a recursive call in
            --  this frequent case.
            First := Env.Get (First.Symbol);
         end if;
         --  Apply phase.
         case First.Kind is
         when Kind_Builtin =>
            declare
               Args : Mal.T_Array (2 .. Ast.L.Length);
            begin
               for I in Args'Range loop
                  Args (I) := Eval (Ast.L.Element (I), Env);
               end loop;
               return First.Builtin.all (Args);
            end;
         when Kind_Function =>
            declare
               Args : Mal.T_Array (2 .. Ast.L.Length);
            begin
               for I in Args'Range loop
                  Args (I) := Eval (Ast.L.Element (I), Env);
               end loop;
               Env.Replace_With_Sub (First.Function_Value.Closure);
               First.Function_Value.Set_Binds (Env, Args);
               Ast := First.Function_Value.Expression;
               goto Restart;
            end;
         when Kind_Macro =>
            declare
               New_Env : constant Environments.Ptr := Env.Sub;
            begin
               First.Function_Value.Set_Binds (New_Env, Ast.L);
               Ast := Eval (First.Function_Value.Expression, New_Env);
            end;
            if Macroexpanding then
               return Ast;
            end if;
            goto Restart;
         when others =>
            raise Argument_Error
              with "cannot execute " & ASU.To_String (Print (First));
         end case;
      when others =>
         return Ast;
      end case;
   end Eval;

   procedure Interactive_Loop (Repl : in Environments.Ptr) is
      use Interfaces.C, Interfaces.C.Strings;
      function Readline (Prompt : in char_array) return chars_ptr
        with Import, Convention => C, External_Name => "readline";
      procedure Add_History (Line : in chars_ptr)
        with Import, Convention => C, External_Name => "add_history";
      procedure Free (Line : in chars_ptr)
        with Import, Convention => C, External_Name => "free";
      Prompt : constant char_array := To_C ("user> ");
      C_Line : chars_ptr;
   begin
      loop
         C_Line := Readline (Prompt);
         exit when C_Line = Null_Ptr;
         declare
            Line : constant String := Value (C_Line);
         begin
            if Line /= "" then
               Add_History (C_Line);
            end if;
            Free (C_Line);
            Ada.Text_IO.Unbounded_IO.Put_Line (Rep (Line, Repl));
         exception
            when Reader.Empty_Source =>
               null;
            when E : Argument_Error | Reader.Reader_Error
              | Environments.Unknown_Key =>
               Ada.Text_IO.Put_Line (Ada.Exceptions.Exception_Information (E));
            when Core.Exception_Throwed =>
               Ada.Text_IO.Put ("User exception: ");
               Ada.Text_IO.Unbounded_IO.Put_Line (Print (Core.Last_Exception));
               Core.Last_Exception := Mal.Nil;
            --  Other exceptions are unexpected.
         end;
      end loop;
      Ada.Text_IO.New_Line;
   end Interactive_Loop;

   function Quasiquote (Ast : in Mal.T;
                        Env : in Environments.Ptr) return Mal.T
   is (case Ast.Kind is
       when Kind_Vector => Quasiquote (Ast.L, Env),
       --  When the test is updated, replace Kind_List with Kind_Vector.
       when Kind_List =>
          (if 0 < Ast.L.Length
             and then Ast.L.Element (1).Kind = Kind_Symbol
             and then Ast.L.Element (1).Symbol = Symbols.Names.Unquote
           then Eval (Ast.L.Element (2), Env)
           else Quasiquote (Ast.L, Env)),
       when others => Ast);

   function Quasiquote (List : in Lists.Ptr;
                        Env  : in Environments.Ptr) return Mal.T is
      --  The final return concatenates these lists.
      R : Mal.T_Array (1 .. List.Length);
   begin
      for I in R'Range loop
         R (I) := List.Element (I);
         if R (I).Kind in Kind_List | Kind_Vector
           and then 0 < R (I).L.Length
           and then R (I).L.Element (1).Kind = Kind_Symbol
           and then R (I).L.Element (1).Symbol = Symbols.Names.Splice_Unquote
         then
            if R (I).L.Length /= 2 then
               raise Argument_Error with "splice-unquote: expects 1 argument";
            end if;
            R (I) := Eval (R (I).L.Element (2), Env);
            if R (I).Kind /= Kind_List then
               raise Argument_Error with "splice-unquote: expects a list";
            end if;
         else
            R (I) := Lists.List (Mal.T_Array'(1 => Quasiquote (R (I), Env)));
         end if;
      end loop;
      return Lists.Concat (R);
   end Quasiquote;

   ----------------------------------------------------------------------

   Startup : constant String := "(do"
     & "(def! not (fn* (a) (if a false true)))"
     & "(def! load-file (fn* (f)"
     & "  (eval (read-string (str ""(do "" (slurp f) "")"")))))"
     & "(defmacro! cond (fn* (& xs)"
     & "  (if (> (count xs) 0)"
     & "    (list 'if (first xs)"
     & "      (if (> (count xs) 1) (nth xs 1)"
     & "        (throw ""odd number of forms to cond""))"
     & "      (cons 'cond (rest (rest xs)))))))"
     & "(defmacro! or (fn* (& xs)"
     & "  (if (empty? xs) nil"
     & "  (if (= 1 (count xs)) (first xs)"
     & "  `(let* (or_FIXME ~(first xs))"
     & "      (if or_FIXME or_FIXME (or ~@(rest xs))))))))"
     & ")";
   Repl : Environments.Ptr renames Environments.Repl;
   use Ada.Command_Line;
begin
   Core.Eval_Ref := Eval'Unrestricted_Access;
   Discard (Eval (Read (Startup), Repl));
   declare
      Args : Mal.T_Array (2 .. Argument_Count);
   begin
      for I in Args'Range loop
         Args (I) := (Kind_String, ASU.To_Unbounded_String (Argument (I)));
      end loop;
      Repl.Set (Symbols.Constructor ("*ARGV*"), Lists.List (Args));
   end;
   if Argument_Count = 0 then
      Interactive_Loop (Repl);
   else
      Discard (Eval (Read ("(load-file """ & Argument (1) & """)"), Repl));
   end if;
end Step9_Try;
