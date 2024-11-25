defmodule QyCore.Params.BezierCurve.Drawer do
  alias QyCore.Params.BezierCurve

  # 这个函数抄的 https://developer.aliyun.com/article/678181
  @spec draw(list(BezierCurve.location()), float()) :: list(BezierCurve.location())
  def draw(control_points, _step) when length(control_points) == 1 do
    control_points
  end

  def draw(control_points, step) when 0.0 < step and step <= 1.0 do
    control_points_num = length(control_points)

    do_draw(control_points, control_points_num, step)
  end

  def draw(_, _), do: raise("Step only can between 0.0 and 1.0.")

  defp do_draw(control_points, control_points_num, step, range \\ +0.0, curve_points \\ [])

  defp do_draw(_, _, step, range, curve_points) when range > (1.0 + step), do: curve_points

  defp do_draw(control_points, control_points_num, step, range, curve_points) do
    new = add_point(control_points, control_points_num, range) |> IO.inspect(label: range)

    do_draw(
      control_points,
      control_points_num,
      step,
      range + step,
      curve_points ++ [new]
    )
  end

  # if (points.Length < 1) { /* 一个点都没有 */
  #   throw new ArgumentOutOfRangeException(); }
  defp add_point(_, control_points_num, _) when control_points_num <= 0, do: raise("control points' number less than 1.")

  # if (count == 1) { return points[0]; }
  defp add_point(points, 1, _), do: points |> :lists.reverse() |> hd()

  defp add_point(control_points, control_points_num, range) do
    [_ | seq2] = [control_points] |> :lists.flatten()

    seq1 =
      [control_points] |> :lists.flatten() |> :lists.reverse() |> tl() |> :lists.reverse()

    # opt_points = for p2 <- seq2, p1 <- seq1, do: execute_calc_point(p1, p2, range)
    opt_points = Enum.zip_with(seq2, seq1, fn p2, p1 -> execute_calc_point(p1, p2, range) end)

    add_point(opt_points, control_points_num - 1, range)
  end

  defp execute_calc_point({x1, y1}, {x2, y2}, range) do
    {x1 * range + x2 * (1 - range), y1 * range + y2 * (1 - range)}
  end
end
