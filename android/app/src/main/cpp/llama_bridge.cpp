#include <jni.h>
#include <string>
#include <vector>
#include <android/log.h>
#include "llama.cpp/include/llama.h"

#define LOG_TAG "USBunny"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO,  LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

struct Session {
    llama_model*   model   = nullptr;
    llama_context* ctx     = nullptr;
    llama_sampler* sampler = nullptr;
};

extern "C" {

JNIEXPORT jlong JNICALL
Java_com_softbitestudio_usbunny_LlamaInference_nativeLoad(
        JNIEnv* env, jobject, jstring jPath, jint nCtx, jint nThreads) {

    const char* path = env->GetStringUTFChars(jPath, nullptr);

    llama_model_params mp = llama_model_default_params();
    llama_model* model = llama_model_load_from_file(path, mp);
    env->ReleaseStringUTFChars(jPath, path);

    if (!model) { LOGE("Failed to load model"); return 0L; }

    llama_context_params cp = llama_context_default_params();
    cp.n_ctx           = nCtx;
    cp.n_threads       = nThreads;
    cp.n_threads_batch = nThreads;

    llama_context* ctx = llama_init_from_model(model, cp);
    if (!ctx) { llama_model_free(model); LOGE("Failed to create context"); return 0L; }

    llama_sampler* sampler = llama_sampler_chain_init(llama_sampler_chain_default_params());
    llama_sampler_chain_add(sampler, llama_sampler_init_temp(0.8f));
    llama_sampler_chain_add(sampler, llama_sampler_init_dist(LLAMA_DEFAULT_SEED));

    LOGI("Model loaded");
    return reinterpret_cast<jlong>(new Session{model, ctx, sampler});
}

JNIEXPORT jstring JNICALL
Java_com_softbitestudio_usbunny_LlamaInference_nativeComplete(
        JNIEnv* env, jobject, jlong ptr, jstring jPrompt, jint maxTokens, jobject cb) {

    auto* s = reinterpret_cast<Session*>(ptr);
    const char* prompt = env->GetStringUTFChars(jPrompt, nullptr);

    const llama_vocab* vocab = llama_model_get_vocab(s->model);

    std::vector<llama_token> tokens(strlen(prompt) + 32);
    int n = llama_tokenize(vocab, prompt, strlen(prompt),
                           tokens.data(), (int)tokens.size(), true, true);
    tokens.resize(n);

    llama_batch batch = llama_batch_get_one(tokens.data(), tokens.size());
    llama_decode(s->ctx, batch);

    jclass  cbClass  = env->GetObjectClass(cb);
    jmethodID onToken = env->GetMethodID(cbClass, "onToken", "(Ljava/lang/String;)V");

    std::string result;
    for (int i = 0; i < maxTokens; i++) {
        llama_token tok = llama_sampler_sample(s->sampler, s->ctx, -1);
        if (llama_vocab_is_eog(vocab, tok)) break;

        char buf[256];
        int len = llama_token_to_piece(vocab, tok, buf, sizeof(buf), 0, true);
        if (len > 0) {
            std::string piece(buf, len);
            result += piece;

            jstring jPiece = env->NewStringUTF(piece.c_str());
            env->CallVoidMethod(cb, onToken, jPiece);
            env->DeleteLocalRef(jPiece);
        }

        llama_batch next = llama_batch_get_one(&tok, 1);
        llama_decode(s->ctx, next);
    }

    env->ReleaseStringUTFChars(jPrompt, prompt);
    return env->NewStringUTF(result.c_str());
}

JNIEXPORT void JNICALL
Java_com_softbitestudio_usbunny_LlamaInference_nativeFree(
        JNIEnv*, jobject, jlong ptr) {
    auto* s = reinterpret_cast<Session*>(ptr);
    if (!s) return;
    if (s->sampler) llama_sampler_free(s->sampler);
    if (s->ctx)     llama_free(s->ctx);
    if (s->model)   llama_model_free(s->model);
    delete s;
}

} // extern "C"
