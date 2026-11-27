<?php

namespace humhub\modules\e2e\commands;

use humhub\modules\file\models\File;
use humhub\modules\post\models\Post;
use humhub\modules\space\models\Space;
use humhub\modules\user\models\User;
use Yii;
use yii\console\Controller;
use yii\console\ExitCode;
use yii\helpers\Console;
use yii\helpers\Url;

/**
 * Seeds and checks fixtures for the mobile app e2e smoke tests.
 *
 * stdout only carries KEY=value lines (sourced by scripts/e2e/run_android.sh);
 * everything else goes to stderr.
 */
class SeedController extends Controller
{
    public const SPACE_NAME = 'E2E';

    /**
     * Creates the E2E space with a post containing an external (YouTube) link,
     * owned by the given user, and prints the fixture URLs.
     */
    public function actionIndex(string $username)
    {
        $user = $this->findUser($username);
        Yii::$app->user->setIdentity($user);

        $space = Space::findOne(['name' => self::SPACE_NAME]);
        if ($space === null) {
            $space = new Space();
            $space->name = self::SPACE_NAME;
            $space->visibility = Space::VISIBILITY_REGISTERED_ONLY;
            $space->join_policy = Space::JOIN_POLICY_NONE;
            if (!$space->save()) {
                return $this->fail('Could not create space', $space->getErrors());
            }
        }

        // humhub/app#368: posts with embedded external links must not pull the
        // app's main webview away from the HumHub origin.
        $post = new Post($space);
        $post->message = 'E2E external link https://www.youtube.com/watch?v=jNQXAC9IVRw';
        if (!$post->save()) {
            return $this->fail('Could not create post', $post->getErrors());
        }

        $this->stdout('E2E_EXTERNAL_LINK_POST_URL=' . Url::to($post->content->getUrl(), true) . PHP_EOL);
        $this->stdout('E2E_DEEP_LINK_TARGET_URL=' . Url::to($space->getUrl(), true) . PHP_EOL);

        return ExitCode::OK;
    }

    /**
     * Exits non-zero unless the given user uploaded a file with the given name.
     */
    public function actionAssertUpload(string $username, string $fileName)
    {
        $user = $this->findUser($username);

        $exists = File::find()
            ->where(['file_name' => $fileName, 'created_by' => $user->id])
            ->exists();

        if (!$exists) {
            return $this->fail("No file '$fileName' uploaded by '$username'");
        }

        $this->stderr("Found uploaded file '$fileName'." . PHP_EOL);

        return ExitCode::OK;
    }

    private function findUser(string $username): User
    {
        $user = User::findOne(['username' => $username]);
        if ($user === null) {
            $this->fail("User '$username' not found");
            exit(ExitCode::DATAERR);
        }

        return $user;
    }

    private function fail(string $message, array $errors = []): int
    {
        $this->stderr($message . PHP_EOL, Console::FG_RED);
        if ($errors !== []) {
            $this->stderr(print_r($errors, true));
        }

        return ExitCode::UNSPECIFIED_ERROR;
    }
}
