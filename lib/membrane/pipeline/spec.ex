defmodule Membrane.Pipeline.Spec do
  @moduledoc """
  Structure representing topology of a pipeline. It can be returned from
  `Membrane.Pipeline.handle_init/1` callback upon pipeline's initialization.
  It will define a topology of children and links that build the pipeline.

  ## Children

  Children that should be spawned when the pipeline starts can be defined
  with the `:children` field.

  You have to set it to a keyword list, where keys are valid element name
  that is unique within this pipeline and values are either element's module or
  struct of that module.

  Sample definitions:

      [
        first_element: %Element.With.Options.Struct{option_a: 42},
        some_element: Element.Without.Options,
        other_element: Element.Using.Default.Options
      ]

  When defining children, some additional parameters can be provided by wrapping
  child definition with a tuple and putting keyword list of parameters at the end:

      [
        first_element: {Element.Bare, indexed: true},
        second_element: {%Element{opt_a: 42}, indexed: true}
      ]

  Available params are described in `t:child_property_t/0`

  ## Links

  Links that should be made when the pipeline starts, and children are spawned
  can be defined with the `:links` field.

  You have to set it to a map, where both keys and values are tuples of
  `{element_name, pad_name}`. Values can also have additional options passed by
  keyword list at the end (See `t:link_option_t/0`).
  Element names have to match names given to the `:children` field.

  Once it's done, pipeline will ensure that links are present.

  Sample definition:

      %{
        {:source,     :output} => {:converter,  :input, pull_buffer: [preferred_size: 20_000]},
        {:converter,  :output} => {:aggregator, :input},
        {:aggregator, :output} => {:sink,  :input},
      }
  """

  alias Membrane.Element
  alias Membrane.Core.PullBuffer
  alias Element.Pad

  @type child_spec_t :: module | struct

  @typedoc """
  Description of all the children elements inside the pipeline
  """
  @type children_spec_t ::
          [{Membrane.Element.name_t(), child_spec_t}]
          | %{Membrane.Element.name_t() => child_spec_t}

  @typedoc """
  Options available when linking elements in the pipeline

  `:pull_buffer` allows to configure Buffer between elements. See `t:Membrane.Core.PullBuffer.props_t/0`
  """
  @type link_option_t :: {:pull_buffer, PullBuffer.props_t()}

  @type link_from_spec_t :: {Element.name_t(), Pad.name_t()}

  @type link_to_spec_t ::
          {Element.name_t(), Pad.name_t()}
          | {Element.name_t(), Pad.name_t(), [link_option_t]}

  @typedoc """
  Map describing links between elements
  """
  @type links_spec_t :: %{required(link_from_spec_t) => link_to_spec_t}

  @typedoc """
  Struct used when launching a pipeline
  """
  @type t :: %__MODULE__{
          children: children_spec_t,
          links: links_spec_t
        }

  defstruct children: [],
            links: %{}
end
