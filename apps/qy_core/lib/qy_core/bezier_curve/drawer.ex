defmodule QyCore.BezierCurve.Drawer do
  # 实在不行就用 NIF 吧
  alias QyCore.BezierCurve

  # 这个函数抄的 https://developer.aliyun.com/article/678181
  # 有了不少魔改
  @spec draw(BezierCurve.control_points(), float()) :: BezierCurve.curve()
  def draw(control_points, _step) when length(control_points) == 1 do
    control_points
  end

  def draw(control_points, step) when 0.0 < step and step <= 1.0 do
    control_points_num = length(control_points)

    do_draw(control_points, control_points_num, step) |> :lists.reverse()
  end

  def draw(_, _), do: raise("Step only can between 0.0 and 1.0.")

  defp do_draw(control_points, control_points_num, step, range \\ +0.0, curve_points \\ [])

  # Include last points
  # 因为精度的问题所以用了这个比较奇葩的方式来做
  defp do_draw(_, _, step, range, curve_points) when range >= 1.0 + step, do: curve_points

  defp do_draw(control_points, control_points_num, step, range, curve_points) do
    new = add_point(control_points, control_points_num, range)

    do_draw(
      control_points,
      control_points_num,
      step,
      range + step,
      [new | curve_points]
      # Add from tail, so in outie of func will reverse again.
    )
  end

  # 一点控制点也没有
  defp add_point(_, control_points_num, _) when control_points_num <= 0,
    do: raise("control points' number less than 1.")

  # 只有一个控制点，返回第一个
  defp add_point(points, 1, _), do: points |> hd()

  defp add_point(control_points, control_points_num, range) do
    control_points = List.wrap(control_points)

    # Tail
    [_ | seq1] = control_points

    # Remove tail
    # :lists.droplast/1 more slowly, but use less memory space.
    seq2 = control_points |> :lists.reverse() |> tl() |> :lists.reverse()

    opt_points = Enum.zip_with(seq1, seq2, fn p1, p2 -> execute_calc_point(p1, p2, range) end)

    add_point(opt_points, control_points_num - 1, range)
  end

  defp execute_calc_point({x1, y1}, {x2, y2}, range) do
    {x1 * range + x2 * (1 - range), y1 * range + y2 * (1 - range)}
  end
end
