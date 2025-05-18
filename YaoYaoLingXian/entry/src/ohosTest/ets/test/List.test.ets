import RequestUtilsTest from './RequestUtils.test'
import DreamEditPageTest from './DreamEditPage.test'
import abilityTest from './Ability.test';

export default function testsuite() {
  abilityTest();
  DreamEditPageTest()
  RequestUtilsTest()
}