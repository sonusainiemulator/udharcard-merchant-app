<?php

namespace App\Http\Controllers;

use App\Mail\SendMail;
use App\Models\Subscriber;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Validator;

class SubscriberController extends Controller
{

    public function index(Request $request)
    {
        $search = $request->search;
        $subscriber = Subscriber::when($search, function ($query, $search) {
            return $query->where('email', 'LIKE', "%{$search}%");
        })->latest()->paginate(basicControl()->paginate ?? 15);

        return view('admin.subscriber.list', compact('subscriber', 'search'));
    }

    public function destroy($id)
    {
        $data = Subscriber::findOrFail($id);
        $data->delete();

        return back()->with('success', 'Subscriber deleted successfully');
    }

    public function sendEmailForm()
    {
        $page_title = 'Send Email to Subscribers';
        return view('admin.subscriber.send_email', compact('page_title'));
    }

    public function sendEmail(Request $request)
    {
        $rules = [
            'subject' => 'required',
            'description' => 'required',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            return back()->withErrors($validator)->withInput();
        }
        $basic = basicControl();
        $email_from = $basic->sender_email;
        $requestMessage = $request->description ?? $request->message;
        $subject = $request->subject;
        $email_body = $basic->email_description;
        if (!Subscriber::first()) return back()->withInput()->with('error', 'No subscribers to send email.');
        $subscribers = Subscriber::all();
        foreach ($subscribers as $subscriber) {
            $name = explode('@', $subscriber->email)[0];
            $message = str_replace("[[name]]", $name, $email_body);
            $message = str_replace("[[message]]", $requestMessage, $message);
            try {
                @Mail::to($subscriber->email)->queue(new SendMail($email_from, $subject, $message));
            } catch (\Exception $e) {
                // Ignore failure for individual address and continue
            }
        }
        return back()->with('success', 'Email has been sent to subscribers.');
    }

}
