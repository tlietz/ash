defmodule Ash.Resource.Dsl do
  @attribute %Ash.Dsl.Entity{
    name: :attribute,
    describe: """
    Declares an attribute on the resource

    Type can be either a built in type (see `Ash.Type`) for more, or a module
    implementing the `Ash.Type` behaviour.
    """,
    examples: [
      """
      attribute :first_name, :string
        primary_key? true
      end
      """
    ],
    transform: {Ash.Resource.Attribute, :transform, []},
    target: Ash.Resource.Attribute,
    args: [:name, :type],
    schema: Ash.Resource.Attribute.attribute_schema()
  }

  @create_timestamp %Ash.Dsl.Entity{
    name: :create_timestamp,
    describe: """
    Declares a non-writable attribute with a create default of `&DateTime.utc_now/0`
    """,
    examples: [
      "create_timestamp :inserted_at"
    ],
    transform: {Ash.Resource.Attribute, :transform, []},
    target: Ash.Resource.Attribute,
    args: [:name],
    schema: Ash.Resource.Attribute.create_timestamp_schema()
  }

  @update_timestamp %Ash.Dsl.Entity{
    name: :update_timestamp,
    describe: """
    Declares a non-writable attribute with a create and update default of `&DateTime.utc_now/0`
    """,
    examples: [
      "update_timestamp :inserted_at"
    ],
    transform: {Ash.Resource.Attribute, :transform, []},
    target: Ash.Resource.Attribute,
    schema: Ash.Resource.Attribute.update_timestamp_schema(),
    args: [:name]
  }

  @integer_primary_key %Ash.Dsl.Entity{
    name: :integer_primary_key,
    describe: """
    Declares a generated (set by the data layer), non writable, non nil, primary key column of type integer
    """,
    examples: [
      "integer_primary_key :id"
    ],
    args: [:name],
    transform: {Ash.Resource.Attribute, :transform, []},
    target: Ash.Resource.Attribute,
    schema: Ash.Resource.Attribute.integer_primary_key_schema()
  }

  @uuid_primary_key %Ash.Dsl.Entity{
    name: :uuid_primary_key,
    describe: """
    Declares a non writable, non nil, primary key column of type uuid, which defaults to `Ash.uuid/0`
    """,
    examples: [
      "uuid_primary_key :id"
    ],
    args: [:name],
    transform: {Ash.Resource.Attribute, :transform, []},
    target: Ash.Resource.Attribute,
    schema: Ash.Resource.Attribute.uuid_primary_key_schema()
  }

  @attributes %Ash.Dsl.Section{
    name: :attributes,
    describe: """
    A section for declaring attributes on the resource.

    Attributes are fields on an instance of a resource. The two required
    pieces of knowledge are the field name, and the type.
    """,
    examples: [
      """
      attributes do
        uuid_primary_key :id

        attribute :first_name, :string do
          allow_nil? false
        end

        attribute :last_name, :string do
          allow_nil? false
        end

        attribute :email, :string do
          allow_nil? false

          constraints [
            match: ~r/^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$/
          ]
        end

        attribute :type, :atom do
          constraints [
            one_of: [:admin, :teacher, :student]
          ]
        end

        create_timestamp :created_at
        update_timestamp :updated_at
      end
      """
    ],
    entities: [
      @attribute,
      @create_timestamp,
      @update_timestamp,
      @integer_primary_key,
      @uuid_primary_key
    ]
  }

  @has_one %Ash.Dsl.Entity{
    name: :has_one,
    describe: """
    Declares a has_one relationship. In a relationsal database, the foreign key would be on the *other* table.

    Generally speaking, a `has_one` also implies that the destination table is unique on that foreign key.
    """,
    examples: [
      """
      # In a resource called `Word`
      has_one :dictionary_entry, DictionaryEntry do
        source_field :text
        destination_field :word_text
      end
      """
    ],
    modules: [:destination],
    target: Ash.Resource.Relationships.HasOne,
    schema: Ash.Resource.Relationships.HasOne.opt_schema(),
    args: [:name, :destination]
  }

  @has_many %Ash.Dsl.Entity{
    name: :has_many,
    describe: """
    Declares a has_many relationship. There can be any number of related entities.
    """,
    examples: [
      """
      # In a resource called `Word`
      has_many :definitions, DictionaryDefinition do
        source_field :text
        destination_field :word_text
      end
      """
    ],
    target: Ash.Resource.Relationships.HasMany,
    modules: [:destination],
    schema: Ash.Resource.Relationships.HasMany.opt_schema(),
    args: [:name, :destination]
  }

  @many_to_many %Ash.Dsl.Entity{
    name: :many_to_many,
    describe: """
    Declares a many_to_many relationship. Many to many relationships require a join table.

    A join table is typically a table who's primary key consists of one foreign key to each resource.
    """,
    examples: [
      """
      # In a resource called `Word`
      many_to_many :books, Book do
        through BookWord
        source_field :text
        source_field_on_join_table: :word_text
        destination_field: :id
        destination_field_on_join_table: :book_id
      end
      """
    ],
    modules: [:destination, :through],
    target: Ash.Resource.Relationships.ManyToMany,
    schema: Ash.Resource.Relationships.ManyToMany.opt_schema(),
    transform: {Ash.Resource.Relationships.ManyToMany, :transform, []},
    args: [:name, :destination]
  }

  @belongs_to %Ash.Dsl.Entity{
    name: :belongs_to,
    describe: """
    Declares a belongs_to relationship. In a relational database, the foreign key would be on the *source* table.

    This creates a field on the resource with the corresponding name and type, unless `define_field?: false` is provided.
    """,
    examples: [
      """
      # In a resource called `Word`
      belongs_to :dictionary_entry, DictionaryEntry do
        source_field :text,
        destination_field: :word_text
      end
      """
    ],
    modules: [:destination],
    target: Ash.Resource.Relationships.BelongsTo,
    schema: Ash.Resource.Relationships.BelongsTo.opt_schema(),
    args: [:name, :destination]
  }

  @relationships %Ash.Dsl.Section{
    name: :relationships,
    describe: """
    A section for declaring relationships on the resource.

    Relationships are a core component of resource oriented design. Many components of Ash
    will use these relationships. A simple use case is side_loading (done via the `Ash.Query.load/2`).
    """,
    examples: [
      """
      relationships do
        belongs_to :post, MyApp.Post do
          primary_key? true
        end

        belongs_to :category, MyApp.Category do
          primary_key? true
        end
      end
      """,
      """
      relationships do
        belongs_to :author, MyApp.Author

        many_to_many :categories, MyApp.Category do
          through MyApp.PostCategory
          destination_field_on_join_table :category_id
          source_field_on_join_table :post_id
        end
      end
      """,
      """
      relationships do
        has_many :posts, MyApp.Post do
          destination_field: :author_id
        end

        has_many :composite_key_posts, MyApp.CompositeKeyPost do
          destination_field :author_id
        end
      end
      """
    ],
    entities: [
      @has_one,
      @has_many,
      @many_to_many,
      @belongs_to
    ]
  }

  @change %Ash.Dsl.Entity{
    name: :change,
    describe: """
    A change to be applied to the changeset after it is generated. They are run in order, from top to bottom.

    To implement your own, see `Ash.Resource.Change`.
    To use it, you can simply refer to the module and its options, like so:

    `change {MyChange, foo: 1}`

    But for readability, you may want to define a function elsewhere and import it,
    so you can say something like:

    `change my_change(1)`

    For destroys, `changes` are not applied unless `soft?` is set to true.
    """,
    examples: [
      "change relate_actor(:reporter)",
      "change {MyCustomChange, :foo}"
    ],
    target: Ash.Resource.Change,
    transform: {Ash.Resource.Change, :transform, []},
    schema: Ash.Resource.Change.schema(),
    args: [:change]
  }

  @action_argument %Ash.Dsl.Entity{
    name: :argument,
    describe: """
    Declares an argument on the action

    The type can be either a built in type (see `Ash.Type`) for more, or a module implementing
    the `Ash.Type` behaviour.
    """,
    examples: [
      "argument :password_confirmation, :string"
    ],
    target: Ash.Resource.Actions.Argument,
    args: [:name, :type],
    schema: Ash.Resource.Actions.Argument.schema()
  }

  @create %Ash.Dsl.Entity{
    name: :create,
    describe: """
    Declares a `create` action. For calling this action, see the `Ash.Api` documentation.
    """,
    examples: [
      """
      create :register do
        primary? true
      end
      """
    ],
    target: Ash.Resource.Actions.Create,
    schema: Ash.Resource.Actions.Create.opt_schema(),
    entities: [
      changes: [
        @change
      ],
      arguments: [
        @action_argument
      ]
    ],
    args: [:name]
  }

  @read %Ash.Dsl.Entity{
    name: :read,
    describe: """
    Declares a `read` action. For calling this action, see the `Ash.Api` documentation.

    ## Pagination

    #{Ash.OptionsHelpers.docs(Ash.Resource.Actions.Read.pagination_schema())}
    """,
    examples: [
      """
      read :read_all do
        primary? true
      end
      """
    ],
    target: Ash.Resource.Actions.Read,
    schema: Ash.Resource.Actions.Read.opt_schema(),
    args: [:name]
  }

  @update %Ash.Dsl.Entity{
    name: :update,
    describe: """
    Declares a `update` action. For calling this action, see the `Ash.Api` documentation.
    """,
    examples: [
      "update :flag_for_review, primary?: true"
    ],
    entities: [
      changes: [
        @change
      ],
      arguments: [
        @action_argument
      ]
    ],
    target: Ash.Resource.Actions.Update,
    schema: Ash.Resource.Actions.Update.opt_schema(),
    args: [:name]
  }

  @destroy %Ash.Dsl.Entity{
    name: :destroy,
    describe: """
    Declares a `destroy` action. For calling this action, see the `Ash.Api` documentation.
    """,
    examples: [
      """
      destroy :soft_delete do
        primary? true
      end
      """
    ],
    entities: [
      changes: [
        @change
      ],
      arguments: [
        @action_argument
      ]
    ],
    target: Ash.Resource.Actions.Destroy,
    schema: Ash.Resource.Actions.Destroy.opt_schema(),
    args: [:name]
  }

  @actions %Ash.Dsl.Section{
    name: :actions,
    describe: """
    A section for declaring resource actions.

    All manipulation of data through the underlying data layer happens through actions.
    There are four types of action: `create`, `read`, `update`, and `destroy`. You may
    recognize these from the acronym `CRUD`. You can have multiple actions of the same
    type, as long as they have different names. This is the primary mechanism for customizing
    your resources to conform to your business logic. It is normal and expected to have
    multiple actions of each type in a large application.

    If you have multiple actions of the same type, one of them must be designated as the
    primary action for that type, via: `primary?: true`. This tells the ash what to do
    if an action of that type is requested, but no specific action name is given.
    """,
    imports: [
      Ash.Resource.Change.Builtins
    ],
    examples: [
      """
      actions do
        create :signup do
          argument :password, :string
          argument :password_confirmation, :string
          change confirm(:password, :password_confirmation)
          change {MyApp.HashPassword, []} # A custom implemented Change
        end

        read :me do
          # An action that auto filters to only return the user for the current user
          filter [id: actor(:id)]
        end

        update :update do
          accept [:first_name, :last_name]
        end

        destroy do
          change set_attribute(:deleted_at, &DateTime.utc_now/0)
          # This tells it that even though this is a delete action, it
          # should be treated like an update because `deleted_at` is set.
          # This should be coupled with a `base_filter` on the resource
          # or with the read actions having a `filter` for `is_nil: :deleted_at`
          soft? true
        end
      end
      """
    ],
    entities: [
      @create,
      @read,
      @update,
      @destroy
    ]
  }

  @identity %Ash.Dsl.Entity{
    name: :identity,
    describe: """
    Represents a unique constraint on the resource.

    Used for indicating that some set of attributes, calculations or aggregates uniquely identify a resource.

    This will allow these fields to be passed to `c:Ash.Api.get/3`, e.g `get(Resource, [some_field: 10])`,
    if all of the keys are filterable. Otherwise they are purely descriptive at the moment.
    The primary key of the resource does not need to be listed as an identity.
    """,
    examples: [
      "identity :name, [:name]",
      "identity :full_name, [:first_name, :last_name]"
    ],
    target: Ash.Resource.Identity,
    schema: Ash.Resource.Identity.schema(),
    args: [:name, :keys]
  }

  @identities %Ash.Dsl.Section{
    name: :identities,
    describe: """
    Unique identifiers for the resource
    """,
    examples: [
      """
      identities do
        identity :full_name, [:first_name, :last_name]
        identity :email, [:email]
      end
      """
    ],
    entities: [
      @identity
    ]
  }

  @resource %Ash.Dsl.Section{
    name: :resource,
    describe: """
    Resource-wide configuration
    """,
    sections: [
      @identities
    ],
    examples: [
      """
      resource do
        description "A description of this resource"
        base_filter [is_nil: :deleted_at]
      end
      """
    ],
    schema: [
      description: [
        type: :string,
        doc: "A human readable description of the resource, to be used in generated documentation"
      ],
      base_filter: [
        type: :any,
        doc: "A filter statement to be applied to any queries on the resource"
      ]
    ]
  }

  @validate %Ash.Dsl.Entity{
    name: :validate,
    describe: """
    Declares a validation for creates and updates.
    """,
    examples: [
      "validate {Mod, [foo: :bar]}",
      "validate at_least_one_of_present([:first_name, :last_name])"
    ],
    target: Ash.Resource.Validation,
    schema: Ash.Resource.Validation.opt_schema(),
    transform: {Ash.Resource.Validation, :transform, []},
    args: [:validation]
  }

  @validations %Ash.Dsl.Section{
    name: :validations,
    describe: """
    Declare validations prior to performing actions against the resource
    """,
    imports: [
      Ash.Resource.Validation.Builtins
    ],
    examples: [
      """
      validations do
        validate {Mod, [foo: :bar]}
        validate at_least_one_of_present([:first_name, :last_name])
      end
      """
    ],
    entities: [
      @validate
    ]
  }

  @count %Ash.Dsl.Entity{
    name: :count,
    describe: """
    Declares a named count aggregate on the resource
    """,
    examples: [
      """
      count :assigned_ticket_count, :assigned_tickets do
        filter [active: true]
      end
      """
    ],
    target: Ash.Resource.Aggregate,
    args: [:name, :relationship_path],
    schema: Ash.Resource.Aggregate.schema(),
    auto_set_fields: [kind: :count]
  }

  @first %Ash.Dsl.Entity{
    name: :first,
    describe: """
    Declares a named `first` aggregate on the resource

    First aggregates return the first value of the related record
    that matches. The relation can be filtered/sorted as well.
    """,
    examples: [
      """
      first :first_assigned_ticket_subject, :assigned_tickets, :subject do
        filter [active: true]
        sort [:subject]
      end
      """
    ],
    target: Ash.Resource.Aggregate,
    args: [:name, :relationship_path, :field],
    schema: Ash.Resource.Aggregate.schema(),
    auto_set_fields: [kind: :first]
  }

  @aggregates %Ash.Dsl.Section{
    name: :aggregates,
    describe: """
    Declare named aggregates on the resource.

    These are aggregates that can be loaded only by name using `Ash.Query.load/2`.
    They are also available as top level fields on the resource.
    """,
    examples: [
      """
      aggregates do
        count :assigned_ticket_count, :reported_tickets do
          filter [active: true]
        end
      end
      """
    ],
    entities: [
      @count,
      @first
    ]
  }

  @argument %Ash.Dsl.Entity{
    name: :argument,
    describe: """
    An argument to be passed into the calculation's arguments map
    """,
    examples: [
      """
      argument :params, :map do
        default %{}
      end
      """,
      """
      argument :retries, :integer do
        allow_nil? false
      end
      """
    ],
    target: Ash.Resource.Calculation.Argument,
    args: [:name, :type],
    schema: Ash.Resource.Calculation.Argument.schema(),
    transform: {Ash.Resource.Calculation.Argument, :transform, []}
  }

  @calculation %Ash.Dsl.Entity{
    name: :calculate,
    describe: """
    Declares a named calculation on the resource.

    Takes a module that must adopt the `Ash.Calculation` behaviour. See that module
    for more information.
    """,
    examples: [
      "calculate :full_name, :string, MyApp.MyResource.FullName",
      "calculate :full_name, :string, {MyApp.FullName, keys: [:first_name, :last_name]}",
      "calculate :full_name, :string, full_name([:first_name, :last_name])"
    ],
    target: Ash.Resource.Calculation,
    args: [:name, :type, :calculation],
    entities: [
      arguments: [@argument]
    ],
    schema: Ash.Resource.Calculation.schema()
  }

  @calculations %Ash.Dsl.Section{
    name: :calculations,
    describe: """
    Declare named calculations on the resource.

    These are calculations that can be loaded only by name using `Ash.Query.load/2`.
    They are also available as top level fields on the resource.
    """,
    examples: [
      """
      calculations do
        calculate :full_name, :string, MyApp.MyResource.FullName
      end
      """
    ],
    imports: [
      Ash.Resource.Calculation.Builtins
    ],
    entities: [
      @calculation
    ]
  }

  @multitenancy %Ash.Dsl.Section{
    name: :multitenancy,
    describe: """
    Options for configuring the multitenancy behavior of a resource.

    To specify a tenant, use `Ash.Query.set_tenant/2` or
    `Ash.Changeset.set_tenant/2` before passing it to an operation.
    """,
    examples: [
      """
      multitenancy do
        strategy :attribute
        attribute :organization_id
        global? true
      end
      """
    ],
    schema: [
      strategy: [
        type: {:in, [:context, :attribute]},
        default: :context,
        doc: """
        Determine how to perform multitenancy. `:attribute` will expect that an
        attribute matches the given `tenant`, e.g `org_id`. `context` (the default)
        implies that the tenant will be passed to the datalayer as context. How a
        given data layer handles multitenancy will differ depending on the implementation.
        See the datalayer documentation for more.
        """
      ],
      attribute: [
        type: :atom,
        doc: """
        If using the `attribute` strategy, the attribute to use, e.g `org_id`
        """
      ],
      global?: [
        type: :boolean,
        doc: """
        Whether or not the data also exists outside of each tenant. This allows running queries
        and making changes without setting a tenant. This may eventually be extended to support
        describing the relationship to global data. For example, perhaps the global data is
        shared among all tenants (requiring "union" support in data layers), or perhaps global
        data is "merged" using some strategy (also requiring "union" support).
        """,
        default: false
      ],
      parse_attribute: [
        type: :mfa,
        doc:
          "An mfa ({module, function, args}) pointing to a function that takes a tenant and returns the attribute value",
        default: {__MODULE__, :identity, []}
      ]
    ]
  }

  @doc false
  def identity(x), do: x

  @sections [
    @attributes,
    @relationships,
    @actions,
    @resource,
    @validations,
    @aggregates,
    @calculations,
    @multitenancy
  ]

  @transformers [
    Ash.Resource.Transformers.SetRelationshipSource,
    Ash.Resource.Transformers.BelongsToAttribute,
    Ash.Resource.Transformers.BelongsToSourceField,
    Ash.Resource.Transformers.CreateJoinRelationship,
    Ash.Resource.Transformers.CachePrimaryKey,
    Ash.Resource.Transformers.SetPrimaryActions,
    Ash.Resource.Transformers.ValidateActionTypesSupported,
    Ash.Resource.Transformers.CountableActions,
    Ash.Resource.Transformers.ValidateMultitenancy
  ]

  @moduledoc """
  The built in resource DSL. The core DSL components of a resource are:

  # Table of Contents
  #{Ash.Dsl.Extension.doc_index(@sections)}

  #{Ash.Dsl.Extension.doc(@sections)}
  """

  use Ash.Dsl.Extension,
    sections: @sections,
    transformers: @transformers
end
