# Smoke test for Apache Cassandra using the DataStax Drivers

Run a subset of the integration test suite of each DataStax driver in order to smoke test Apache Cassandra releases.

## AppVeyor Project

https://ci.appveyor.com/project/DataStax/cassandra-drivers-smoke-test/

## Other CI Service Providers

This project currently uses [AppVeyor](https://www.appveyor.com/), if needed, it can easily be migrated to other CI
 Service Provider as all the logic on `install.sh` is provider agnostic.

## License

© DataStax, Inc.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
