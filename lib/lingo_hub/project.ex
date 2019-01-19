defmodule LingoHub.Project do
  @type t :: %__MODULE__{
          title: String.t(),
          name: String.t(),
          account: String.t()
        }

  defstruct title: nil, name: nil, account: nil
end
