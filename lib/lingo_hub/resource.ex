defmodule LingoHub.Resource do
  @type t :: %__MODULE__{
          locale: String.t(),
          account: String.t(),
          project: String.t(),
          name: String.t()
        }

  defstruct locale: nil, account: nil, project: nil, name: nil
end
