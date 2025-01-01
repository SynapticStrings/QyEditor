defmodule QyCore.NoteTest do
  use ExUnit.Case

  alias QyCore.Note
  alias QyCore.Note.Distance
  doctest Note

  describe "将 SPN 转变为内在形式" do
    test "转换合法的类型" do
      assert Note.parse_spn("rest") == :rest

      assert Note.parse_spn("A4") == {:a, :natural, 4}
      assert Note.parse_spn("Eb5") == {:e, :flat, 5}
      assert Note.parse_spn("bb3") == {:b, :flat, 3}
    end

    test "完全非法的类型" do
      assert Note.parse_spn("invalid note") == :invalid_note

      assert Note.parse_spn("l#4") == :invalid_note

      assert_raise ArgumentError, fn -> Note.parse_spn("lw") end
    end
  end

  describe "将内在类型转变为 SPN" do
    test "合法类型" do
      assert Note.note_to_text(:rest) == "rest"

      assert Note.note_to_text({:c, :natual, 2}) == "C2"

      assert Note.note_to_text({:b, :flat, 3}) == "Bb3"
    end
  end

  describe "整理音符" do
    test "处理重升重降" do
      assert "C##4" |> Note.parse_spn() |> Note.format() == {:d, :natural, 4}
      assert "D##4" |> Note.parse_spn() |> Note.format() == {:e, :natural, 4}
      assert "E##4" |> Note.parse_spn() |> Note.format() == {:f, :sharp, 4}
      assert "F##4" |> Note.parse_spn() |> Note.format() == {:g, :natural, 4}
      assert "G##4" |> Note.parse_spn() |> Note.format() == {:a, :natural, 4}
      assert "A##4" |> Note.parse_spn() |> Note.format() == {:b, :natural, 4}
      assert "B##4" |> Note.parse_spn() |> Note.format() == {:c, :sharp, 5}

      assert "Cbb4" |> Note.parse_spn() |> Note.format() == {:b, :flat, 3}
      assert "Dbb4" |> Note.parse_spn() |> Note.format() == {:c, :natural, 4}
      assert "Ebb4" |> Note.parse_spn() |> Note.format() == {:d, :natural, 4}
      assert "Fbb4" |> Note.parse_spn() |> Note.format() == {:e, :flat, 4}
      assert "Gbb4" |> Note.parse_spn() |> Note.format() == {:f, :natural, 4}
      assert "Abb4" |> Note.parse_spn() |> Note.format() == {:g, :natural, 4}
      assert "Bbb4" |> Note.parse_spn() |> Note.format() == {:a, :natural, 4}
    end

    test "实际上是白键的黑键" do
      assert "e#4" |> Note.parse_spn() |> Note.format() == {:f, :natural, 4}

      assert "b#4" |> Note.parse_spn() |> Note.format() == {:c, :natural, 5}

      assert "fb4" |> Note.parse_spn() |> Note.format() == {:e, :natural, 4}

      assert "cb4" |> Note.parse_spn() |> Note.format() == {:b, :natural, 3}
    end

    test "同名异音" do
      assert {:c, :sharp, 3} |> Note.format(preference: :sharp) == {:c, :sharp, 3}
    end

    test "八度操作" do
      #
    end
  end

  describe "比较两个音之间的高低" do
    test "等音高" do
      a4 = "A4" |> Note.parse_spn()

      assert Note.same?(a4, a4)

      assert not Note.same?({:a, :sharp, 3}, {:a, :sharp, 4})
      assert not Note.same?({:a, :sharp, 3}, {:a, :flat, 3})
    end

    test "同音异名的等音高" do
      assert Note.same?({:a, :sharp, 1}, {:b, :flat, 1})

      assert Note.same?({:a, :ss, 1}, {:b, :natural, 1})

      assert Note.same?({:f, :flat, 1}, {:e, :natural, 1})
    end

    test "不同八度的音不一样" do
      assert not Note.same?({:a, :sharp, 1}, {:a, :sharp, 2})

      assert Note.same?({:b, :sharp, 1}, {:c, :natural, 2})

      assert Note.same?({:c, :flat, 2}, {:b, :natural, 1})

      assert Note.higher?({:b, :sharp, 1}, {:c, :flat, 2})
    end
  end

  describe "计算音之间的距离" do
    test "可能包含休止符" do
      assert Distance.calculate_distance_sign(:rest, :rest) == {:invalid, :maybe_has_rest_note}

      assert Distance.calculate_distance_sign(:rest, {:a, :natural, 4}) == {:invalid, :maybe_has_rest_note}
    end

    test "一度、八度、十五度" do
      ## 纯一度
      # 一个音
      assert Distance.calculate_distance_sign({:a, :natural, 4}, {:a, :natural, 4}) ==
               {:perfect, 1}

      # 同音异名（减二度）
      assert Distance.calculate_distance_sign({:c, :sharp, 3}, {:d, :flat, 3}) ==
               {:diminished, 2}

      assert Distance.calculate_distance_sign({:c, :natural, 4}, {:b, :sharp, 3}) ==
               {:diminished, 2}

      # 八度以及十五度、二十二度，甚至更多
      assert Distance.calculate_distance_sign({:a, :natural, 4}, {:a, :natural, 3}) ==
               {:perfect, 8}

      assert Distance.calculate_distance_sign({:a, :natural, 2}, {:a, :natural, 4}) ==
                {:perfect, 15}

      assert Distance.calculate_distance_sign({:a, :natural, 5}, {:a, :natural, 2}) ==
                {:perfect, 22}
    end

    test "二度" do
      # 大二度
      assert Distance.calculate_distance_sign({:c, :sharp, 3}, {:d, :sharp, 3}) == {:major, 2}

      # 小二度
    end

    test "三度" do
      # 大三度
      assert Distance.calculate_distance_sign({:c, :natural, 4}, {:e, :natural, 4}) == {:major, 3}

      # 小三度
      assert Distance.calculate_distance_sign({:d, :natural, 4}, {:f, :natural, 4}) == {:minor, 3}
    end

    test "纯四度" do
      assert Distance.calculate_distance_sign({:c, :natural, 4}, {:f, :natural, 4}) == {:perfect, 4}
    end

    test "纯五度" do
      assert Distance.calculate_distance_sign({:c, :natural, 4}, {:g, :natural, 4}) == {:perfect, 5}
    end

    test "六度" do
      # 大六度

      # 小六度
    end

    test "七度" do
      # 大七度
      assert Distance.calculate_distance_sign({:c, :natural, 4}, {:b, :natural, 4}) == {:major, 7}

      # 小七度
      assert Distance.calculate_distance_sign({:c, :natural, 4}, {:b, :flat, 4}) == {:minor, 7}
    end
  end

  describe "十二平均律下的音高计算" do
    test "TwelveETAdapter" do
      alias Distance.TwelveETAdapter, as: TET

      base = {{:a, :natural, 4}, 440.0}

      assert_in_delta TET.calculate_distance_pitch(base, {:a, :natural, 4}), 440.0, 0.01

      assert_in_delta TET.calculate_distance_pitch(base, {:c, :natural, 4}), 261.63, 0.01

      assert_in_delta TET.calculate_distance_pitch(base, {:b, :natural, 7}), 3951.1, 0.1
    end

    # 加管弦乐曲式的音高（A4 = 442 Hz）吗？

    test "在 Note 模块中" do
      # 休止符
      assert_in_delta Note.do_convert_note(:rest), 0.0, 0.01

      assert_in_delta Note.do_convert_note({:a, :natural, 4}), 440.0, 0.01

      assert_in_delta Note.do_convert_note({:a, :natural, 2}), 110.0, 0.01

      assert_in_delta Note.do_convert_note({:b, :natural, 7}), 3951.1, 0.1

      # assert Note.do_convert_note(:invalid_name)
    end

    # bla bla
  end
end
