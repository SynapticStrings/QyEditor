defmodule WebUI.Demo do
  use WebUI, :live_view

  def render(assigns) do
    ~H"""
    Current temperature: {@temperature}°F <button phx-click="inc_temperature">+</button>
    <button phx-click="dec_temperature">-</button>
    """
  end

  def mount(_params, _session, socket) do
    temperature = 70
    {:ok, assign(socket, :temperature, temperature)}
  end

  def handle_event("inc_temperature", _async_fun_result, socket) do
    {:noreply, update(socket, :temperature, &(&1 + 1))}
  end

  def handle_event("dec_temperature", _async_fun_result, socket) do
    {:noreply, update(socket, :temperature, &(&1 - 1))}
  end
end
