/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.wso2.am.integration.tests.jwt.idp;

import org.testng.annotations.DataProvider;
import org.testng.annotations.Factory;
import org.wso2.carbon.automation.engine.context.TestUserMode;

import java.util.Arrays;
import java.util.List;

public class TokenExchangeMultiValueClaimDisabledTestCase extends TokenExchangeMultiValueClaimBaseTest {

    @Factory(dataProvider = "userModeDataProvider")
    public TokenExchangeMultiValueClaimDisabledTestCase(TestUserMode userMode) {

        super(userMode);
    }

    @DataProvider
    public static Object[][] userModeDataProvider() {

        return new Object[][] { new Object[] { TestUserMode.SUPER_TENANT_ADMIN },
                new Object[] { TestUserMode.TENANT_ADMIN } };
    }

    @Override
    protected List<String> getExpectedGroups() {

        return Arrays.asList("[engineering", " support", " analytics]");
    }

    @Override
    protected String getTestNameSuffix() {

        return "Disabled";
    }
}
