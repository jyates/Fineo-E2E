package io.fineo.e2e.options;

import com.beust.jcommander.Parameter;
import com.google.inject.Guice;
import com.google.inject.Injector;
import com.google.inject.Module;
import io.fineo.e2e.module.FakeAwsCredentialsModule;
import io.fineo.etl.FineoProperties;
import io.fineo.lambda.configure.PropertiesModule;
import io.fineo.lambda.configure.SchemaStoreModule;
import io.fineo.lambda.configure.dynamo.DynamoModule;
import io.fineo.lambda.dynamo.DynamoTestConfiguratorModule;
import io.fineo.schema.store.SchemaStore;

import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

import static com.google.common.collect.Lists.newArrayList;

/**
 * Options for the location of a locally running (e.g. not in amazon) store
 */
public class LocalSchemaStoreOptions {

  @Parameter(names = "--port", description = "Port on which dynamo is running")
  public int port = -1;

  @Parameter(names = "--host", description = "Hostname where dynamo is running")
  public String host;

  @Parameter(names = "--schema-table", description = "Table where schema information is stored")
  public String schemaTable;

  public SchemaStore getStore() {
    Injector guice = Guice.createInjector(getSchemaStoreModules());
    return guice.getInstance(SchemaStore.class);
  }

  public List<Module> getSchemaStoreModules() {
    List<Module> modules = new ArrayList<Module>();
    // support for local dynamo
    modules.add(new FakeAwsCredentialsModule());
    modules.add(new DynamoTestConfiguratorModule());
    modules.add(new DynamoModule());
    modules.add(new SchemaStoreModule());

    // properties to support the build
    Properties props = new Properties();
    props.setProperty(FineoProperties.DYNAMO_URL_FOR_TESTING, "http://" + host + ":" + port);
    props.setProperty(FineoProperties.DYNAMO_SCHEMA_STORE_TABLE, schemaTable);
    props.setProperty(FineoProperties.DYNAMO_READ_LIMIT, "1");
    props.setProperty(FineoProperties.DYNAMO_WRITE_LIMIT, "1");

    modules.add(new PropertiesModule(props));

    return modules;
  }
}
