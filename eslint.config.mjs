// @ts-check

// @ts-ignore
import babelParser from '@babel/eslint-parser';
import importAssertPlugin from '@babel/plugin-syntax-import-assertions';
import eslint from '@eslint/js';
import cypressPlugin from 'eslint-plugin-cypress';
import mochaPlugin from 'eslint-plugin-mocha';
import hooksPlugin from 'eslint-plugin-react-hooks';
import simpleImportSort from 'eslint-plugin-simple-import-sort';
import unusedImports from 'eslint-plugin-unused-imports';
import globals from 'globals';
import tseslint from 'typescript-eslint';

const todo_promoteToError = 'warn';

export default tseslint.config(
    eslint.configs.recommended,
    // Awkward setup; see https://github.com/facebook/react/issues/28313
    {
        plugins: {
            // @ts-ignore
            'react-hooks': hooksPlugin,
            'simple-import-sort': simpleImportSort,
            'unused-imports': unusedImports,
        },
        rules: {
            'react-hooks/rules-of-hooks': 'error',
            'react-hooks/exhaustive-deps': 'error',
            'simple-import-sort/imports': 'error',
            'simple-import-sort/exports': 'error',
            'unused-imports/no-unused-imports': 'error',
        },
        languageOptions: {
            ecmaVersion: 2022,
            sourceType: 'module',
            globals: {
                ...globals.browser,
                ...globals.node,
            },
        },
    },
);
