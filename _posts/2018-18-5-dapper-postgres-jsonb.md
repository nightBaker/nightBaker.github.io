1. first of all we have to create interface 

Dapper
Npgsql

```csharp
public interface IRepository<T> where T : class
{
	Task AddAsync(T item);
	Task RemoveAsync(T item);
	Task UpdateAsync(T item);
	Task<T> FindAsync(long id);
	Task<IEnumerable<T>> FindAsync(Expression<Func<T, object>> filter, object value);
	Task<IEnumerable<T>> FindAllAsync();
}
```

2. create few entities

```csharp
public class Operation 
{
		
	public long Id { get;  set; }
	
	public DateTime CreatedAt { get;  set; }

	public JObject Attachment { get; set; }

	public int OperationTypeId { get;  set; }

	public OperationType OperationType { get;  set; }
}

public class OperationType
{
	
	public int Id { get; set; }	

	public string Description { get; set; }
	
}
	
```

3. implement base repository

DapperExtensions

```csharp
internal class BaseRepository<T>: IRepository<T>  where T : class
{
	protected string _connectionString;        
						
	public BaseRepository(string connectionString)
	{
		_connectionString = connectionString;            
	}

	public async Task AddAsync(T item)
	{
		using (IDbConnection cn = await _getConnectionAsync())
		{                                
			await cn.InsertAsync<T>(item);

			cn.Close();
		}
	}

	public async Task<IEnumerable<T>> FindAsync(Expression<Func<T, object>> filter, object value)
	{
		using (var db = await _getConnectionAsync())
		{
			var predicate = Predicates.Field(filter, Operator.Eq, value);
			var result = await db.GetListAsync<T>(predicate);
			db.Close();
			return result;
		}
	}

	public async Task<IEnumerable<T>> FindAllAsync()
	{
		using (var db = await _getConnectionAsync())
		{                
			var result = await db.GetListAsync<T>();
			db.Close();
			return result;
		}
	}

	public async Task<T> FindAsync(long id)
	{
		using (var db = await _getConnectionAsync())
		{
			var result = await db.GetAsync<T>(id);
			db.Close();
			return result;
		}
	}

	public async Task RemoveAsync(T item)
	{
		using (var db = await _getConnectionAsync())
		{
			var result = await db.DeleteAsync<T>(item);
			db.Close();                
		}
	}

	public async Task UpdateAsync(T item)
	{
		using (var db = await _getConnectionAsync())
		{
			var result = await db.UpdateAsync<T>(item);
			db.Close();
		}
	}
	

	/// <summary>
	/// creates connection to database
	/// </summary>
	/// <returns>opened connection</returns>
	private async Task<IDbConnection> _getConnectionAsync()
	{
		var conn = new NpgsqlConnection(_connectionString);
		await conn.OpenAsync();
		return conn;
	}
}


```
	
4. create dbcontext which contains all repositories

```csharp
public class DbContext
{
	
	public DbContext(string connectionString)
	{
		//postgres support
		DapperExtensions.DapperAsyncExtensions.SqlDialect = new PostgreSqlDialect();
		//jobject to db jsonb handler
		SqlMapper.AddTypeHandler(typeof(JObject), JObjectHandler.Instance);

		OperationTypes = new BaseRepository<OperationType>(connectionString);
		Operations = new BaseRepository<Operation>(connectionString);
		TokenStatuses = new BaseRepository<TokenStatus>(connectionString);
		Tokens = new BaseRepository<Token>(connectionString);
	}

	public IRepository<OperationType> OperationTypes { get; private set; }
	public IRepository<Operation> Operations { get; private set; }        
}
```

5. add mappers 

```csharp
public class OperationMapper: ClassMapper<Operation>
{
	public OperationMapper()
	{
		Table("operations");

		Map(x => x.Id).Key(KeyType.Identity);

		Map(x => x.CreatedAt).Column("registration_ts");
		Map(x => x.OperationTypeId).Column("operation_type");

		Map(x => x.OperationType).Ignore();

		//map all other columns
		AutoMap();
	}
}

 public class OperationTypeMapper: ClassMapper<OperationType>
{
	public OperationTypeMapper()
	{
		Table("operation_types");

		Map(x => x.Id).Key(KeyType.Identity);

		//map all other columns
		AutoMap();
	}
}
```


5. add jobject handler
```csharp
class JObjectHandler : TypeHandler<JObject>
{
	private JObjectHandler() { }
	public static JObjectHandler Instance { get; } = new JObjectHandler();
	public override JObject Parse(object value)
	{
		var json = (string)value;
		return json == null ? null : JObject.Parse(json);
	}
	public override void SetValue(IDbDataParameter parameter, JObject value)
	{
		parameter.Value = value?.ToString(Newtonsoft.Json.Formatting.None);
		((NpgsqlParameter)parameter).NpgsqlDbType = NpgsqlDbType.Jsonb;
	}
}
```
