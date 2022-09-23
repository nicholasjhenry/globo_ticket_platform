defmodule GloboTicket.Promotions.ActsTest do
  use GloboTicket.DataCase

  alias GloboTicket.Promotions.Acts.Controls
  alias GloboTicket.Promotions.Acts.Handlers
  alias GloboTicket.Promotions.Acts.Store

  test "acts are initially empty" do
    acts = Handlers.Queries.list_acts()
    assert Enum.empty?(acts)
  end

  test "when act added then a act is returned" do
    act_info = Controls.Act.example()

    result = Handlers.Commands.save_act(act_info)

    assert {:ok, _record} = result
    acts = Handlers.Queries.list_acts()
    assert Enum.any?(acts, &(&1.id == act_info.id))
  end

  test "when act added twice then one act is added" do
    act_info = Controls.Act.example()
    _result = Handlers.Commands.save_act(act_info)

    result = Handlers.Commands.save_act(act_info)

    assert {:ok, _record} = result
    acts = Handlers.Queries.list_acts()
    assert Enum.count(acts) == 1
  end

  test "when set act description then act description is returned" do
    act_info = Controls.Act.example(title: "Gabriel Iglesias")

    _result = Handlers.Commands.save_act(act_info)

    act = Store.get_act!(act_info.id)
    assert act.title == "Gabriel Iglesias"
  end

  test "when set act description to the same description then nothing is saved" do
    act_info = Controls.Act.example(title: "Gabriel Iglesias")
    _result = Handlers.Commands.save_act(act_info)
    first_snapshot = Store.get_act!(act_info.id)

    _result = Handlers.Commands.save_act(act_info)

    second_snapshot = Store.get_act!(act_info.id)
    assert second_snapshot.last_updated_ticks == first_snapshot.last_updated_ticks
  end

  test "when act is modified concurrently then exception is thrown" do
    act_info = Controls.Act.example(title: "Gabriel Iglesias")

    _result = Handlers.Commands.save_act(act_info)
    act = Store.get_act!(act_info.id)

    act_info =
      Controls.Act.example(
        title: "Change 1",
        last_updated_ticks: act.last_updated_ticks
      )

    _result = Handlers.Commands.save_act(act_info)

    assert_raise Ecto.StaleEntryError, fn ->
      act_info =
        Controls.Act.example(
          title: "Change 2",
          last_updated_ticks: act.last_updated_ticks
        )

      Handlers.Commands.save_act(act_info)
    end
  end

  test "when act deleted act is not returned" do
    act_info = Controls.Act.example()
    _result = Handlers.Commands.save_act(act_info)

    _result = Handlers.Commands.delete_act(act_info.id)

    assert_raise Ecto.NoResultsError, fn -> Store.get_act!(act_info.id) end
  end
end
