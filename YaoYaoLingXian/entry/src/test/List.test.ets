import DreamEditPageTest from './DreamEditPage.test'
import localUnitTest from './LocalUnit.test';

export default function testsuite() {
  localUnitTest();
  DreamEditPageTest()
}