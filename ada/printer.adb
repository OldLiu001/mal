package body Printer is

   function Pr_Str (M : Types.Smart_Pointer) return String is
   begin
     if Types.Is_Null (M) then
        return "";
     else
        return Types.To_String (Types.Deref (M).all);
     end if;
   end Pr_Str;

end Printer;
