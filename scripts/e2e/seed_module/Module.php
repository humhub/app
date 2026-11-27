<?php

namespace humhub\modules\e2e;

use Yii;
use yii\console\Application;

/**
 * Fixture seeding for the mobile app e2e smoke tests.
 * Mounted into the disposable test container only, never deployed.
 */
class Module extends \humhub\components\Module
{
    public function init()
    {
        parent::init();

        if (Yii::$app instanceof Application) {
            $this->controllerNamespace = 'humhub\modules\e2e\commands';
        }
    }
}
