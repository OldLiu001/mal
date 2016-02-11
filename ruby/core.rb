require "readline"
require_relative "reader"
require_relative "printer"

$core_ns = {
    :"=" =>       lambda {|a,b| a == b},
    :throw =>     lambda {|a| raise MalException.new(a), "Mal Exception"},
    :nil? =>      lambda {|a| a == nil},
    :true? =>     lambda {|a| a == true},
    :false? =>    lambda {|a| a == false},
    :string? =>   lambda {|a| (a.is_a? String) && "\u029e" != a[0]},
    :symbol =>    lambda {|a| a.to_sym},
    :symbol? =>   lambda {|a| a.is_a? Symbol},
    :keyword =>   lambda {|a| "\u029e"+a},
    :keyword? =>  lambda {|a| (a.is_a? String) && "\u029e" == a[0]},

    :"pr-str" =>  lambda {|*a| a.map {|e| _pr_str(e, true)}.join(" ")},
    :str =>       lambda {|*a| a.map {|e| _pr_str(e, false)}.join("")},
    :prn =>       lambda {|*a| puts(a.map {|e| _pr_str(e, true)}.join(" "))},
    :println =>   lambda {|*a| puts(a.map {|e| _pr_str(e, false)}.join(" "))},
    :readline =>  lambda {|a| Readline.readline(a,true)},
    :"read-string" => lambda {|a| read_str(a)},
    :slurp =>     lambda {|a| File.read(a)},
    :< =>         lambda {|a,b| a < b},
    :<= =>        lambda {|a,b| a <= b},
    :> =>         lambda {|a,b| a > b},
    :>= =>        lambda {|a,b| a >= b},
    :+ =>         lambda {|a,b| a + b},
    :- =>         lambda {|a,b| a - b},
    :* =>         lambda {|a,b| a * b},
    :/ =>         lambda {|a,b| a / b},
    :"time-ms" => lambda {|| (Time.now.to_f * 1000).to_i},

    :list =>      lambda {|*a| List.new a},
    :list? =>     lambda {|*a| a[0].is_a? List},
    :vector =>    lambda {|*a| Vector.new a},
    :vector? =>   lambda {|*a| a[0].is_a? Vector},
    :"hash-map" =>lambda {|*a| Hash[a.each_slice(2).to_a]},
    :map? =>      lambda {|a| a.is_a? Hash},
    :assoc =>     lambda {|*a| a[0].merge(Hash[a.drop(1).each_slice(2).to_a])},
    :dissoc =>    lambda {|*a| h = a[0].clone; a.drop(1).each{|k| h.delete k}; h},
    :get =>       lambda {|a,b| return nil if a == nil; a[b]},
    :contains? => lambda {|a,b| a.key? b},
    :keys =>      lambda {|a| List.new a.keys},
    :vals =>      lambda {|a| List.new a.values},

    :sequential? => lambda {|a| sequential?(a)},
    :cons =>      lambda {|a,b| List.new(b.clone.insert(0,a))},
    :concat =>    lambda {|*a| List.new(a && a.reduce(:concat) || [])},
    :nth =>       lambda {|a,b| raise "nth: index out of range" if b >= a.size; a[b]},
    :first =>     lambda {|a| a.nil? ? nil : a[0]},
    :rest =>      lambda {|a| List.new(a.nil? || a.size == 0 ? [] : a.drop(1))},
    :empty? =>    lambda {|a| a.size == 0},
    :count =>     lambda {|a| return 0 if a == nil; a.size},
    :apply =>     lambda {|*a| a[0][*a[1..-2].concat(a[-1])]},
    :map =>       lambda {|a,b| List.new(b.map {|e| a[e]})},

    :conj =>      lambda {|*a| a[0].clone.conj(a.drop(1))},
    :seq =>       lambda {|a| a.nil? ? nil : a.size == 0 ? nil : a.seq},

    :"with-meta" => lambda {|a,b| x = a.clone; x.meta = b; x},
    :meta =>      lambda {|a| a.meta},
    :atom =>      lambda {|a| Atom.new(a)},
    :atom? =>     lambda {|a| a.is_a? Atom},
    :deref =>     lambda {|a| a.val},
    :reset! =>    lambda {|a,b| a.val = b},
    :swap! =>     lambda {|*a| a[0].val = a[1][*[a[0].val].concat(a.drop(2))]},
}

